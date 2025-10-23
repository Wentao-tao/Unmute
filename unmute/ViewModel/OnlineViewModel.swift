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

    // MARK: - Public Methods
    
    /// Starts the transcription session by connecting to the service and beginning audio capture.
    /// Sets up callback handlers for receiving transcription results.
    func start() async {
        isRunning = true
        
        // Clear previous transcription results
        finalLines.clear()
        partialLine = ""

        // Configure callback to handle incoming transcription tokens
        ws.onTokens = { [weak self] finals, partials in
            guard let self else { return }

            // Process finalized transcription results
            if !finals.isEmpty {
                // Group consecutive tokens from the same speaker within this batch
                var currentSpeaker = -1
                var currentText = ""
                var shouldForceNewLine = false
                
                for final in finals {
                    // Check if this is an endpoint marker
                    if final.isEndpoint {
                        // Save current accumulated text if any
                        if !currentText.isEmpty {
                            let text = currentText
                            let speaker = currentSpeaker
                            Task { @MainActor in
                                self.finalLines.appendOrAdd(text: text, speaker: speaker)
                            }
                            currentText = ""
                        }
                        // Set flag to force new line for next text
                        shouldForceNewLine = true
                        continue
                    }
                    
                    if currentSpeaker == -1 {
                        // First token in this batch
                        currentSpeaker = final.speaker
                        currentText = final.text
                    } else if currentSpeaker != final.speaker {
                        // Speaker changed - save previous speaker's accumulated text
                        let text = currentText
                        let speaker = currentSpeaker
                        let forceNewLine = shouldForceNewLine
                        Task { @MainActor in
                            self.finalLines.appendOrAdd(text: text, speaker: speaker, forceNewLine: forceNewLine)
                        }
                        shouldForceNewLine = false
                        
                        // Start new group
                        currentSpeaker = final.speaker
                        currentText = final.text
                    } else {
                        // Same speaker
                        if shouldForceNewLine && !currentText.isEmpty {
                            // Need to force new line - save current and start fresh
                            let text = currentText
                            let speaker = currentSpeaker
                            Task { @MainActor in
                                self.finalLines.appendOrAdd(text: text, speaker: speaker, forceNewLine: true)
                            }
                            currentText = final.text
                            shouldForceNewLine = false
                        } else {
                            // Normal accumulation
                            currentText += final.text
                        }
                    }
                }
                
                // Save the last accumulated text from this batch
                if !currentText.isEmpty {
                    let text = currentText
                    let speaker = currentSpeaker
                    Task { @MainActor in
                        self.finalLines.appendOrAdd(text: text, speaker: speaker)
                    }
                }

                // Clear partial line when we get final results
                Task { @MainActor in
                    self.partialLine = ""
                }
            }

            // Update partial (in-progress) transcription display
            if !partials.isEmpty {
                let partialText = partials.map(\.text).joined()
                Task { @MainActor in
                    self.partialLine = partialText
                }
            }
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
