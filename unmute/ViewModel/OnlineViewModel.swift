//
//  OnlineViewModel.swift
//  unmute
//
//  Created by Wentao Guo on 20/10/25.
//

import SwiftUI

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
    
    /// WebSocket service for online transcription
    private let ws = OnlineTransciberService()
    
    /// Audio capture service
    private let avAduio = AvAudioService()
    
    /// Background task that streams audio chunks to the transcription service
    private var pushTask: Task<Void, Error>?
    
    /// Flag to track if next text should start a new line (set by endpoint detection)
    private var shouldForceNewLine = false

    // MARK: - Public Methods
    
    /// Starts the transcription session by connecting to the service and beginning audio capture.
    /// Sets up callback handlers for receiving transcription results.
    func start() async {
        isRunning = true
        
        // Clear previous transcription results and state
        finalLines.clear()
        partialLine = ""
        shouldForceNewLine = false

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

    /// Starts audio capture and streams audio chunks to the transcription service.
    /// Runs in a detached background task to avoid blocking the main thread.
    func sendData() {
        // Start audio capture
        let frames: AsyncStream<AudioFrame>
        do {
            frames = try avAduio.start()
        } catch {
            return
        }

        // Create background task to process and send audio
        self.pushTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            // Audio chunk configuration
            let chunkDur: Double = 0.12           // 120ms chunks
            let sr = 48_000                       // 48kHz sample rate
            let bytesPerSample = MemoryLayout<Float>.size  // Float32 = 4 bytes
            let channels = 1                      // Mono audio
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
                    self.ws.sendAudioChunk(chunk)
                    chunk.removeAll(keepingCapacity: true)
                }
            }

            // Send any remaining audio data
            if !chunk.isEmpty {
                self.ws.sendAudioChunk(chunk)
            }

            // Finalize transcription and close connection
            self.ws.finalize()
            self.ws.close()
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
        
        for token in tokens {
            if token.isEndpoint {
                // Endpoint detected - save current text and prepare for new line
                handleEndpointToken(currentText: &currentText, currentSpeaker: currentSpeaker)
            } else if currentSpeaker == -1 {
                // First token in this batch
                currentSpeaker = token.speaker
                currentText = token.text
            } else if currentSpeaker != token.speaker {
                // Speaker changed
                handleSpeakerChange(
                    currentText: currentText,
                    currentSpeaker: currentSpeaker,
                    newToken: token,
                    newSpeaker: &currentSpeaker,
                    newText: &currentText
                )
            } else {
                // Same speaker
                handleSameSpeakerToken(currentText: &currentText, token: token)
            }
        }
        
        // Save the last accumulated text from this batch
        if !currentText.isEmpty {
            saveTranscriptionLine(text: currentText, speaker: currentSpeaker, forceNewLine: false)
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
    private func handleEndpointToken(currentText: inout String, currentSpeaker: Int) {
        if !currentText.isEmpty {
            saveTranscriptionLine(text: currentText, speaker: currentSpeaker, forceNewLine: false)
            currentText = ""
        }
        shouldForceNewLine = true
    }
    
    /// Handles a speaker change by saving previous speaker's text and starting new group.
    /// - Parameters:
    ///   - currentText: Current accumulated text
    ///   - currentSpeaker: Current speaker ID
    ///   - newToken: New token with different speaker
    ///   - newSpeaker: Will be set to new speaker ID
    ///   - newText: Will be set to new token's text
    private func handleSpeakerChange(
        currentText: String,
        currentSpeaker: Int,
        newToken: OnlineTransciberService.Token,
        newSpeaker: inout Int,
        newText: inout String
    ) {
        // Save previous speaker's accumulated text
        let forceNewLine = shouldForceNewLine
        saveTranscriptionLine(text: currentText, speaker: currentSpeaker, forceNewLine: forceNewLine)
        shouldForceNewLine = false
        
        // Start new group with new speaker
        newSpeaker = newToken.speaker
        newText = newToken.text
    }
    
    /// Handles a token from the same speaker, either appending or starting new line.
    /// - Parameters:
    ///   - currentText: Current accumulated text
    ///   - token: New token from same speaker
    private func handleSameSpeakerToken(currentText: inout String, token: OnlineTransciberService.Token) {
        if shouldForceNewLine {
            // Endpoint was detected - force new line
            if !currentText.isEmpty {
                saveTranscriptionLine(text: currentText, speaker: token.speaker, forceNewLine: true)
            }
            currentText = token.text
            shouldForceNewLine = false
        } else {
            // Normal accumulation - append to existing text
            currentText += token.text
        }
    }
    
    /// Saves a transcription line to the model.
    /// - Parameters:
    ///   - text: Text content to save
    ///   - speaker: Speaker ID
    ///   - forceNewLine: Whether to force a new line even for same speaker
    private func saveTranscriptionLine(text: String, speaker: Int, forceNewLine: Bool) {
        Task { @MainActor in
            self.finalLines.appendOrAdd(text: text, speaker: speaker, forceNewLine: forceNewLine)
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
        avAduio.stop()

        // Cancel the audio streaming task if it exists
        // The task will handle finalize() and close() in its cleanup
        if let task = pushTask {
            task.cancel()
            pushTask = nil
        } else {
            // If no task exists, manually finalize and close
            ws.finalize()
            ws.close()
        }
    }
}
