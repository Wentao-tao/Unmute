//
//  OnlineTransciberService.swift
//  unmute
//
//  Created by Wentao Guo on 20/10/25.
//

import Foundation

/// Service class that handles real-time speech-to-text transcription via Soniox WebSocket API.
/// Supports speaker diarization and streaming partial/final transcription results.
final class OnlineTransciberService {
    
    // MARK: - Types
    
    /// Represents a single transcription token with speaker information
    struct Token {
        let text: String        // The transcribed text content
        let isFinal: Bool       // Whether this is a final or partial result
        let speaker: Int        // Speaker ID (1, 2, 3, etc.) or -1 if unknown
        let isEndpoint: Bool    // Whether this token marks an endpoint (pause/sentence boundary)
    }

    // MARK: - Public Properties
    
    /// Callback invoked when new tokens are received from the transcription service.
    /// - Parameters:
    ///   - finals: Array of finalized tokens
    ///   - partial: Array of partial (in-progress) tokens
    var onTokens: ((_ finals: [Token], _ partial: [Token]) -> Void)?

    // MARK: - Private Properties
    
    /// Configuration dictionary for the Soniox API connection
    let config: [String: Any] = [
        "api_key": "eabe473113f3c7c46bf0a9bb0d111cd4ad0d5bdb9f60067201c5a64fb4ae4dd0",
        "model": "stt-rt-preview",
        "language_hints": ["en"],
        "enable_speaker_diarization": true,
        "context": """
            This is a meeting for developers.
        """,
        "enable_endpoint_detection": true,
        "audio_format": "pcm_f32le",
        "sample_rate": 48000,
        "num_channels": 1,
    ]

    private var task: URLSessionWebSocketTask?
    private let url = URL(
        string: "wss://stt-rt.soniox.com/transcribe-websocket"
    )!

    // MARK: - Public Methods
    
    /// Establishes WebSocket connection and sends initial configuration.
    /// - Throws: Connection or configuration errors
    func connectAndStart() async throws {
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: url)

        // Start listening for messages before resuming the connection
        receiveLoop()

        // Begin WebSocket connection
        task?.resume()

        // Wait for connection to stabilize before sending config
        try await Task.sleep(nanoseconds: 500_000_000)

        // Send configuration as JSON text message (required by Soniox API)
        if let json = try? JSONSerialization.data(withJSONObject: config),
            let jsonString = String(data: json, encoding: .utf8)
        {
            task?.send(.string(jsonString)) { err in
                if let err {
                    print("Error sending config: \(err)")
                }
            }
        }
    }

    /// Sends a chunk of raw PCM audio data to the transcription service.
    /// - Parameter data: Raw Float32 PCM audio data (48kHz, mono)
    func sendAudioChunk(_ data: Data) {
        task?.send(.data(data)) { _ in }
    }

    /// Signals the end of audio stream and requests final transcription results.
    func finalize() {
        let msg = try! JSONSerialization.data(withJSONObject: [
            "type": "finalize"
        ])
        if let msgString = String(data: msg, encoding: .utf8) {
            task?.send(.string(msgString)) { _ in }
        }
    }

    /// Sends a keepalive message to maintain the WebSocket connection.
    func keepalive() {
        let msg = try! JSONSerialization.data(withJSONObject: [
            "type": "keepalive"
        ])
        if let msgString = String(data: msg, encoding: .utf8) {
            task?.send(.string(msgString)) { _ in }
        }
    }

    /// Closes the WebSocket connection and releases resources.
    func close() {
        // Send empty data frame to signal end
        task?.send(.data(Data())) { _ in }
        // Cancel the WebSocket task
        task?.cancel(with: .goingAway, reason: nil)
    }

    // MARK: - Private Methods
    
    /// Continuously receives messages from the WebSocket connection.
    /// Handles both binary data and text messages, parsing them as JSON.
    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                // Connection failed or was closed
                print("WebSocket receive error: \(error)")
                return

            case .success(let message):
                // Handle both data and string message formats
                if case .data(let d) = message {
                    self.handleMessageData(d)
                } else if case .string(let str) = message {
                    if let d = str.data(using: .utf8) {
                        self.handleMessageData(d)
                    }
                }

                // Continue receiving messages
                self.receiveLoop()
            }
        }
    }

    /// Parses received JSON data and extracts transcription tokens.
    /// - Parameter data: JSON data received from the WebSocket
    private func handleMessageData(_ data: Data) {
        // Parse JSON response
        guard
            let obj = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any]
        else {
            return
        }

        // Check for error responses
        if let errorCode = obj["error_code"] as? Int {
            print("Transcription service error code: \(errorCode)")
            return
        }

        // Check if transcription has finished
        if let finished = obj["finished"] as? Bool, finished {
            print("Transcription session finished")
            return
        }

        // Process token array if present
        if let arr = obj["tokens"] as? [[String: Any]] {
            var finals: [Token] = []
            var partial: [Token] = []

            for t in arr {
                // Extract text content
                guard let text = t["text"] as? String else {
                    continue
                }

                // Check if this is an endpoint marker
                let isEndpoint = (text == "<end>")
                
                // Skip empty endpoint markers for text, but keep them as signals
                if isEndpoint && text == "<end>" {
                    // Create a special endpoint token
                    let endpointToken = Token(
                        text: "",
                        isFinal: true,
                        speaker: -1,
                        isEndpoint: true
                    )
                    finals.append(endpointToken)
                    continue
                }

                // Extract speaker ID with multiple type handling
                // The speaker field can come as Int, NSNumber, or String from JSON
                let speakerValue: Int
                if let speakerNum = t["speaker"] as? Int {
                    speakerValue = speakerNum
                } else if let speakerNum = t["speaker"] as? NSNumber {
                    speakerValue = speakerNum.intValue
                } else if let speakerNum = t["speaker"] as? String,
                    let intValue = Int(speakerNum)
                {
                    speakerValue = intValue
                } else {
                    speakerValue = -1
                }

                // Create token with extracted data
                let tok = Token(
                    text: text,
                    isFinal: (t["is_final"] as? Bool) ?? false,
                    speaker: speakerValue,
                    isEndpoint: false
                )

                // Categorize as final or partial result
                if tok.isFinal {
                    finals.append(tok)
                } else {
                    partial.append(tok)
                }
            }

            // Notify callback if we have any tokens
            if !finals.isEmpty || !partial.isEmpty {
                self.onTokens?(finals, partial)
            }
        }
    }
}
