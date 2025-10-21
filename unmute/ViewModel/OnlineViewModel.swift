//
//  OnlineViewModel.swift
//  unmute
//
//  Created by Wentao Guo on 20/10/25.
//

import SwiftUI

@Observable
final class OnlineViewModel {
    var finalLines: TranscriberModel = TranscriberModel()
    var partialLine: String = ""
    var isRunning: Bool = false

    private let ws = OnlineTransciberService()
    private let avAduio = AvAudioService()
    private var pushTask: Task<Void, Error>?

    func start() async {
        isRunning = true
        ws.onTokens = { [weak self] finals, partials in
            guard let self else { return }
            if !finals.isEmpty {
                var text = ""
                var speaker = ""
                for final in finals {
                    if speaker == "" {
                        speaker = final.speaker
                    }
                    if speaker != final.speaker {
                        Task { @MainActor in
                            self.finalLines.add([text: speaker])
                        }
                        text = ""
                        speaker = final.speaker
                        text += final.text
                    } else {
                        text += final.text
                    }
                }
                Task { @MainActor in
                    self.finalLines.add([text: speaker])
                }

                Task { @MainActor in

                    self.partialLine = ""
                }
            }

            if !partials.isEmpty {
                Task { @MainActor in
                    self.partialLine = partials.map(\.text).joined()
                }
            }
        }
        do {
            try await ws.connectAndStart()
        } catch {
            print(error)
        }
       
        sendDate()
    }

    func sendDate() {
        let frames = try! avAduio.start()
        self.pushTask = Task.detached(priority: .userInitiated) { [weak self] in
        guard let self else { return }
        let chunkDur: Double = 0.12
        let sr = 48_000
        let bytesPerSample = MemoryLayout<Float>.size
        let channels = 1
        let chunkBytesTarget =
            Int(Double(sr) * chunkDur) * channels * bytesPerSample

        var chunk = Data()
        chunk.reserveCapacity(chunkBytesTarget * 2)

        for await f in frames {
            try Task.checkCancellation()
            if let ch = f.buffer.floatChannelData?.pointee {
                let count = Int(f.buffer.frameLength) * bytesPerSample
                let raw = UnsafeRawBufferPointer(start: ch, count: count)
                chunk.append(contentsOf: raw)
            }

            if chunk.count >= chunkBytesTarget {
                self.ws.sendAudioChunk(chunk)
                chunk.removeAll(keepingCapacity: true)
            }

        }
        if !chunk.isEmpty { self.ws.sendAudioChunk(chunk) }
        self.ws.finalize()
        self.ws.close()

    }

    }
    
    func stop() {
        isRunning = false
        pushTask?.cancel()
        pushTask = nil
        avAduio.stop()
        ws.finalize()
        ws.close()
    }
}
