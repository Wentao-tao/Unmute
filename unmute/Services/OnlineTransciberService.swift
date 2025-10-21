//
//  OnlineTransciberService.swift
//  unmute
//
//  Created by Wentao Guo on 20/10/25.
//

import Foundation

final class OnlineTransciberService {
    struct Token {
        let text: String
        let isFinal: Bool
        let speaker: String
    }

    // Callbacks to push results to VM/UI
    var onTokens: ((_ finals: [Token], _ partial: [Token]) -> Void)?

    let config: [String: Any] = [
        "api_key":
            "eabe473113f3c7c46bf0a9bb0d111cd4ad0d5bdb9f60067201c5a64fb4ae4dd0",
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

    func connectAndStart() async throws {
        print("Attempting to connect to:", url)
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: url)
        print("WebSocket task created, state:", task?.state.rawValue ?? -1)
        
        receiveLoop()
        
        
        task?.resume()
        print("WebSocket resumed, state:", task?.state.rawValue ?? -1)

        // 等待一小段时间让连接建立
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒

        // 验证连接状态
        guard task?.state == .running else {
            throw NSError(
                domain: "WebSocket",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to establish WebSocket connection"
                ]
            )
        }

        // 1) send config JSON first
        if let json = try? JSONSerialization.data(withJSONObject: config) {
            task?.send(.data(json)) { err in
                if let err = err { print("send config:", err) }
            }
        }
        
    }

    // Send a raw PCM chunk (e.g., 100–120 ms of Float32 48k mono)
    func sendAudioChunk(_ data: Data) {
        task?.send(.data(data)) { err in
            if let err = err { print("send audio:", err) }
        }
    }

    func finalize() {
        let msg = try! JSONSerialization.data(withJSONObject: [
            "type": "finalize"
        ])
        task?.send(.data(msg)) { err in
            if let err = err { print("finalize:", err) }
        }
    }

    func keepalive() {
        let msg = try! JSONSerialization.data(withJSONObject: [
            "type": "keepalive"
        ])
        task?.send(.data(msg)) { err in
            if let err = err { print("keepalive:", err) }
        }
    }

    func close() {
        task?.send(.data(Data())) { _ in }  // optional end-of-audio signal
        task?.cancel(with: .goingAway, reason: nil)
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                print("ws recv error:", error)

            case .success(let message):
                if case .data(let d) = message,
                    let obj = try? JSONSerialization.jsonObject(with: d)
                        as? [String: Any]
                {

                    if let arr = obj["tokens"] as? [[String: Any]] {
                        var finals: [Token] = []
                        var partial: [Token] = []
                        for t in arr {
                            guard let text = t["text"] as? String else {
                                continue
                            }
                            let tok = Token(
                                text: text,
                                isFinal: (t["is_final"] as? Bool) ?? false,
                                speaker: t["speaker"] as? String ?? "unknown"
                            )
                            tok.isFinal
                                ? finals.append(tok) : partial.append(tok)
                        }
                        // Push to UI (caller ensures main-thread if needed)
                        self.onTokens?(finals, partial)
                    }

                }
                // keep receiving
                self.receiveLoop()
            }
        }
    }
}
