//
//  OnlineViewModel.swift
//  unmute
//
//  Created by Wentao Guo on 20/10/25.
//

import SwiftUI
import SwiftData

/// ViewModel that orchestrates real-time audio capture and online transcription.
/// Manages the connection between audio input, transcription service, and UI updates.
@Observable
final class OnlineViewModel {

    // MARK: - Public Properties

    /// Model containing finalized transcription lines with speaker information
    var finalLines: TranscriberModel = TranscriberModel()

    /// Current partial (in-progress) transcription text
    var partialLine: String = ""

    /// Whether the transcription is currently active
    var isRunning: Bool = false

    // MARK: - Private Properties

    /// WebSocket service for online transcription (lazy loaded)
    private var ws: OnlineTransciberService?

    /// Audio capture service (lazy loaded to prevent audio engine conflicts on init)
    private var avAduio: AvAudioService?
    
    /// Background task that streams audio chunks to the transcription service
    private var pushTask: Task<Void, Error>?

    /// Flag to track if next text should start a new line (set by endpoint detection)
    private var shouldForceNewLine = false
    
    /// Speaker ID to name mapping (for quick lookup without voice recognition)
    private var speakerMapping: [Int: String] = [:]
    
    /// Set of speakers with auto-learning enabled
    private var autoLearnEnabled: Set<Int> = []
    
    /// Pending enrollments for speakers that haven't reached 5 seconds yet
    private var pendingEnrollments: [Int: PendingEnrollment] = [:]
    
    /// Set of learned audio segments (to avoid duplicate learning)
    private var learnedSegments: Set<String> = []
    
    /// Data structure for pending enrollment
    struct PendingEnrollment {
        let name: String
        var totalDuration: Int
        var timeRanges: [(Int, Int)]
    }

    // MARK: - Public Methods

    /// Starts the transcription session by connecting to the service and beginning audio capture.
    /// Sets up callback handlers for receiving transcription results.
    func start() async {
        isRunning = true

        // Clear previous transcription results and state
        finalLines.clear()
        partialLine = ""
        shouldForceNewLine = false
        
        // Clear speaker mappings for new session
        speakerMapping.removeAll()
        autoLearnEnabled.removeAll()
        pendingEnrollments.removeAll()
        learnedSegments.removeAll()

        // Initialize services lazily (prevents audio engine conflicts on view init)
        if ws == nil {
            ws = OnlineTransciberService()
        }
        if avAduio == nil {
            avAduio = AvAudioService()
        }
        
        guard let ws = ws else {
            isRunning = false
            return
        }

        // Configure callback to handle incoming transcription tokens
        ws.onTokens = { [weak self] finals, partials in
            guard let self else { return }

            self.processFinalTokens(finals)
            self.updatePartialLine(partials)
        }

        // Connect to transcription service
        do {
            try await ws.connectAndStart()
        } catch {
            isRunning = false
            return
        }

        // Begin audio capture and streaming
        sendData()
    }

    /// Enroll a speaker manually by name
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - time: Time range of the audio segment
    ///   - id: Speaker ID from transcription service
    func enrol(name: String, time: Time_sx, id: Int) {
        // Collect all historical time segments for this speaker
        let timeRanges = collectSpeakerSegments(speakerId: id)
        
        // Calculate total duration
        let totalDuration = timeRanges.reduce(0) { $0 + ($1.1 - $1.0) }
        
        // Check if we have at least 5 seconds (5000ms) of audio
            if totalDuration >= 5000 {
                Task {
                    let success = await VoiceService.shared.enrollMultipleSegments(
                        name: name,
                        timeRanges: timeRanges
                    )
                
                    if success {
                    await MainActor.run {
                        self.speakerMapping[id] = name
                        self.autoLearnEnabled.insert(id)
                        self.markSegmentsAsLearned(speakerId: id, timeRanges: timeRanges)
                        self.finalLines.updateName(name: name, id: id)
                        self.pendingEnrollments.removeValue(forKey: id)
                    }
                } else {
                    print("❌ Failed to enroll speaker '\(name)'")
                }
            }
        } else {
            // Not enough audio yet, mark as pending enrollment
            pendingEnrollments[id] = PendingEnrollment(
                name: name,
                totalDuration: totalDuration,
                timeRanges: timeRanges
            )
        }
    }

    /// Starts audio capture and streams audio chunks to the transcription service.
    /// Runs in a detached background task to avoid blocking the main thread.
    func sendData() {
        // Create background task to process and send audio
        self.pushTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            guard let avAduio = self.avAduio else { return }
            
            // Start audio capture (audio setup now runs asynchronously to prevent UI blocking)
            let frames: AsyncStream<AudioFrame>
            do {
                frames = try await avAduio.start()
            } catch {
                return
            }

            // Audio chunk configuration
            let chunkDur: Double = 0.12  // 120ms chunks
            let sr = 16_000  // 16kHz sample rate
            let bytesPerSample = MemoryLayout<Float>.size  // Float32 = 4 bytes
            let channels = 1  // Mono audio
            let chunkBytesTarget =
                Int(Double(sr) * chunkDur) * channels * bytesPerSample

            var chunk = Data()
            chunk.reserveCapacity(chunkBytesTarget * 2)

            // Process incoming audio frames
            for await f in frames {
                try Task.checkCancellation()

                // Extract raw Float32 audio data from buffer
                if let ch = f.buffer.floatChannelData?.pointee {
                    let count = Int(f.buffer.frameLength) * bytesPerSample
                    let raw = UnsafeRawBufferPointer(start: ch, count: count)
                    chunk.append(contentsOf: raw)
                }

                // Send chunk when it reaches target size
                if chunk.count >= chunkBytesTarget {
                    self.ws?.sendAudioChunk(chunk)
                    chunk.removeAll(keepingCapacity: true)
                }
            }

            // Send any remaining audio data
            if !chunk.isEmpty {
                self.ws?.sendAudioChunk(chunk)
            }

            // Finalize transcription and close connection
            self.ws?.finalize()
            self.ws?.close()
        }
    }

    // MARK: - Private Methods

    /// Processes finalized transcription tokens and updates the UI.
    /// Groups consecutive tokens from the same speaker and handles endpoints.
    /// - Parameter tokens: Array of finalized transcription tokens
    private func processFinalTokens(_ tokens: [OnlineTransciberService.Token]) {
        guard !tokens.isEmpty else { return }

        var currentSpeaker = -1
        var currentText = ""
        var start_ms = 0
        var end_ms = 0

        for token in tokens {
            if token.isEndpoint {
                // Endpoint detected - save current text and prepare for new line
                handleEndpointToken(
                    currentText: &currentText,
                    currentSpeaker: &currentSpeaker,
                    start: start_ms,
                    end: end_ms
                )
            } else if currentSpeaker == -1 {
                // First token in this batch
                currentSpeaker = token.speaker
                currentText = token.text
                start_ms = token.start_ms
                end_ms = token.end_ms
            } else if currentSpeaker != token.speaker {
                // Speaker changed
                handleSpeakerChange(
                    currentText: currentText,
                    currentSpeaker: currentSpeaker,
                    startTime: start_ms,
                    endTime: end_ms,
                    newToken: token,
                    newStartTime: &start_ms,
                    newEndTime: &end_ms,
                    newSpeaker: &currentSpeaker,
                    newText: &currentText
                )
            } else {
                // Same speaker
                handleSameSpeakerToken(
                    currentText: &currentText,
                    token: token,
                    newStartTime: &start_ms,
                    newEndTime: &end_ms
                )
            }
        }

        // Save the last accumulated text from this batch
        if !currentText.isEmpty {
            saveTranscriptionLine(
                text: currentText,
                speaker: currentSpeaker,
                forceNewLine: false,
                start: start_ms,
                end: end_ms
            )
        }

        // Clear partial line when we get final results
        Task { @MainActor in
            self.partialLine = ""
        }
    }

    /// Handles an endpoint token by saving current text and setting force new line flag.
    /// - Parameters:
    ///   - currentText: Current accumulated text (will be cleared)
    ///   - currentSpeaker: Current speaker ID
    ///   - start: Start time in milliseconds
    ///   - end: End time in milliseconds
    private func handleEndpointToken(
        currentText: inout String,
        currentSpeaker: inout Int,
        start: Int,
        end: Int
    ) {
        if !currentText.isEmpty {
            saveTranscriptionLine(
                text: currentText,
                speaker: currentSpeaker,
                forceNewLine: false,
                start: start,
                end: end
            )
            currentText = ""
            currentSpeaker = -1
        }
        shouldForceNewLine = true
    }

    /// Handles a speaker change by saving previous speaker's text and starting new group.
    /// - Parameters:
    ///   - currentText: Current accumulated text
    ///   - currentSpeaker: Current speaker ID
    ///   - startTime: Start time of current segment
    ///   - endTime: End time of current segment
    ///   - newToken: New token with different speaker
    ///   - newStartTime: Will be set to new token's start time
    ///   - newEndTime: Will be set to new token's end time
    ///   - newSpeaker: Will be set to new speaker ID
    ///   - newText: Will be set to new token's text
    private func handleSpeakerChange(
        currentText: String,
        currentSpeaker: Int,
        startTime: Int,
        endTime: Int,
        newToken: OnlineTransciberService.Token,
        newStartTime: inout Int,
        newEndTime: inout Int,
        newSpeaker: inout Int,
        newText: inout String
    ) {
        // Save previous speaker's accumulated text
        let forceNewLine = shouldForceNewLine
        saveTranscriptionLine(
            text: currentText,
            speaker: currentSpeaker,
            forceNewLine: forceNewLine,
            start: startTime,
            end: endTime
        )
        shouldForceNewLine = false

        // Start new group with new speaker
        newStartTime = newToken.start_ms
        newSpeaker = newToken.speaker
        newText = newToken.text
        newEndTime = newToken.end_ms
    }

    /// Handles a token from the same speaker, either appending or starting new line.
    /// - Parameters:
    ///   - currentText: Current accumulated text
    ///   - token: New token from same speaker
    ///   - newStartTime: Start time reference
    ///   - newEndTime: Will be updated to token's end time
    private func handleSameSpeakerToken(
        currentText: inout String,
        token: OnlineTransciberService.Token,
        newStartTime: inout Int,
        newEndTime: inout Int
    ) {
        if shouldForceNewLine {
            // Endpoint was detected - force new line
            if !currentText.isEmpty {
                saveTranscriptionLine(
                    text: currentText,
                    speaker: token.speaker,
                    forceNewLine: true,
                    start: newStartTime,
                    end: newEndTime
                )
            }
            currentText = token.text
            newStartTime = token.start_ms
            newEndTime = token.end_ms
            shouldForceNewLine = false
        } else {
            // Normal accumulation - append to existing text
            currentText += token.text
            newEndTime = token.end_ms
        }
    }

    /// Saves a transcription line to the model and handles speaker identification/learning.
    /// - Parameters:
    ///   - text: Text content to save
    ///   - speaker: Speaker ID
    ///   - forceNewLine: Whether to force a new line even for same speaker
    ///   - start: Start time in milliseconds
    ///   - end: End time in milliseconds
    private func saveTranscriptionLine(
        text: String,
        speaker: Int,
        forceNewLine: Bool,
        start: Int,
        end: Int
    ) {
        let sliceTime = Time_sx(start_ms: start, end_ms: end)
        
        Task { @MainActor in
            self.finalLines.appendOrAdd(
                text: text,
                speaker: speaker,
                forceNewLine: forceNewLine,
                time: sliceTime
            )
            
            let currentIndex = self.finalLines.name.indices.last
            
            // Strategy 1: Use existing mapping if available
            if let mappedName = self.speakerMapping[speaker] {
                if let index = currentIndex, index < self.finalLines.name.count {
                    self.finalLines.name[index] = mappedName
                }
                Task.detached {
                    await self.autoLearnIfReady(speaker: speaker, name: mappedName)
                }
                return
            }
            
            // Strategy 2: Check pending enrollment status
            if let _ = self.pendingEnrollments[speaker] {
                Task.detached {
                    await self.checkPendingEnrollment(speaker: speaker)
                }
                return
            }
            
            // Strategy 3: Handle new speaker (attempt identification)
            Task.detached {
                await self.handleNewSpeaker(speaker: speaker, currentIndex: currentIndex)
            }
        }
    }
    
    /// Handles a new speaker by attempting identification
    /// - Parameters:
    ///   - speaker: Speaker ID to handle
    ///   - currentIndex: Current index in finalLines
    private func handleNewSpeaker(speaker: Int, currentIndex: Int?) async {
        let timeRanges = collectSpeakerSegments(speakerId: speaker)
        let totalDuration = timeRanges.reduce(0) { $0 + ($1.1 - $1.0) }
        
        // Only attempt identification if we have at least 5 seconds
            if totalDuration >= 5000 {
                let result = await VoiceService.shared.identifyMultipleSegments(timeRanges: timeRanges)
            
            _ = await MainActor.run {
                if let (identifiedName, score) = result {
                    if score >= 0.80 {
                        if let index = currentIndex, index < self.finalLines.name.count {
                            // Check for mapping conflicts (same name mapped to different speaker ID)
                            let hasConflict = self.speakerMapping.contains { (id, name) in
                                name == identifiedName && id != speaker
                            }
                            
                            if !hasConflict {
                                self.finalLines.name[index] = identifiedName
                                self.speakerMapping[speaker] = identifiedName
                                self.autoLearnEnabled.insert(speaker)
                                self.markSegmentsAsLearned(speakerId: speaker, timeRanges: timeRanges)
                                self.finalLines.updateName(name: identifiedName, id: speaker)
                            } else {
                                print("⚠️ Identification conflict: '\(identifiedName)' already mapped to different speaker")
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Checks if pending enrollment has reached 5 seconds and completes enrollment
    /// - Parameter speaker: Speaker ID to check
    private func checkPendingEnrollment(speaker: Int) async {
        guard let pending = pendingEnrollments[speaker] else { return }
        
        let timeRanges = collectSpeakerSegments(speakerId: speaker)
        let totalDuration = timeRanges.reduce(0) { $0 + ($1.1 - $1.0) }
        
        // Complete enrollment if we now have enough audio
        if totalDuration >= 5000 {
            let success = await VoiceService.shared.enrollMultipleSegments(
                name: pending.name,
                timeRanges: timeRanges
            )
            
            if success {
                await MainActor.run {
                    self.speakerMapping[speaker] = pending.name
                    self.autoLearnEnabled.insert(speaker)
                    self.markSegmentsAsLearned(speakerId: speaker, timeRanges: timeRanges)
                    self.finalLines.updateName(name: pending.name, id: speaker)
                    self.pendingEnrollments.removeValue(forKey: speaker)
                }
            } else {
                print("❌ Failed to complete pending enrollment for '\(pending.name)'")
            }
        }
    }
    
    /// Auto-learning: Automatically adds new voice samples with quality validation
    /// - Parameters:
    ///   - speaker: Speaker ID
    ///   - name: Speaker's name
    private func autoLearnIfReady(speaker: Int, name: String) async {
        guard autoLearnEnabled.contains(speaker) else { return }
        
        let timeRanges = collectUnlearnedSegments(speakerId: speaker)
        let totalDuration = timeRanges.reduce(0) { $0 + ($1.1 - $1.0) }
        
        // Only attempt learning if we have at least 5 seconds of unlearned audio
        if totalDuration >= 5000 {
            // Use validation method with threshold 0.85 (stricter than identification threshold 0.8)
            let success = await VoiceService.shared.enrollMultipleSegmentsWithValidation(
                name: name,
                timeRanges: timeRanges,
                minSimilarity: 0.85
            )
            
            if success {
                // Quality validation passed, mark as learned
                await MainActor.run {
                    self.markSegmentsAsLearned(speakerId: speaker, timeRanges: timeRanges)
                }
            } else {
                // Quality validation failed - likely misidentification
                // Disable auto-learning for this speaker to prevent voiceprint contamination
                print("⚠️ Auto-learning quality validation failed for speaker \(speaker) - disabling to prevent contamination")
                _ = await MainActor.run {
                    self.autoLearnEnabled.remove(speaker)
                }
            }
        }
    }

    /// Updates the partial (in-progress) transcription display.
    /// - Parameter tokens: Array of partial transcription tokens
    private func updatePartialLine(_ tokens: [OnlineTransciberService.Token]) {
        guard !tokens.isEmpty else { return }

        let partialText = tokens.map(\.text).joined()
        Task { @MainActor in
            self.partialLine = partialText
        }
    }

    /// Stops the transcription session and releases all resources.
    /// Cancels audio capture and closes the WebSocket connection.
    func stop() {
        isRunning = false
        avAduio?.stop()

        // Cancel the audio streaming task if it exists
        // The task will handle finalize() and close() in its cleanup
        if let task = pushTask {
            task.cancel()
            pushTask = nil
        } else {
            // If no task exists, manually finalize and close
            ws?.finalize()
            ws?.close()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Collects all audio segments for a specific speaker
    /// - Parameter speakerId: Speaker ID to collect segments for
    /// - Returns: Array of (start, end) time ranges in milliseconds
    private func collectSpeakerSegments(speakerId: Int) -> [(Int, Int)] {
        var ranges: [(Int, Int)] = []
        for (index, sid) in finalLines.speakers.enumerated() {
            if sid == speakerId, index < finalLines.times.count {
                let t = finalLines.times[index]
                ranges.append((t.start_ms, t.end_ms))
            }
        }
        return ranges
    }
    
    /// Collects unlearned audio segments for a specific speaker
    /// - Parameter speakerId: Speaker ID to collect unlearned segments for
    /// - Returns: Array of (start, end) time ranges in milliseconds for unlearned segments
    private func collectUnlearnedSegments(speakerId: Int) -> [(Int, Int)] {
        var ranges: [(Int, Int)] = []
        for (index, sid) in finalLines.speakers.enumerated() {
            if sid == speakerId, index < finalLines.times.count {
                let t = finalLines.times[index]
                let key = "\(speakerId)_\(t.start_ms)_\(t.end_ms)"
                if !learnedSegments.contains(key) {
                    ranges.append((t.start_ms, t.end_ms))
                }
            }
        }
        return ranges
    }
    
    /// Marks audio segments as learned (to avoid duplicate learning)
    /// - Parameters:
    ///   - speakerId: Speaker ID
    ///   - timeRanges: Array of (start, end) time ranges to mark as learned
    private func markSegmentsAsLearned(speakerId: Int, timeRanges: [(Int, Int)]) {
        for (start, end) in timeRanges {
            let key = "\(speakerId)_\(start)_\(end)"
            learnedSegments.insert(key)
        }
    }
    
    // MARK: - Session Management
    
    /// Saves the current transcription session to SwiftData
    /// - Parameters:
    ///   - modelContext: SwiftData model context
    ///   - title: Optional custom title for the session
    /// - Returns: The saved TranscriptionSession
    @MainActor
    func saveSession(to modelContext: ModelContext, title: String = "") async -> TranscriptionSession {
        return await finalLines.saveSession(to: modelContext, title: title)
    }
}
