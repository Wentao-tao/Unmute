//
//  TestViewModel.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import AVFoundation

@MainActor
final class TestViewModel: ObservableObject {
    @Published var state: String = "Idle"
    @Published var lastFileURL: URL?

    private let capture = AvAudioService()
    private var recordTask: Task<Void, Never>?
    private var player: AVAudioPlayer?

    /// Record `seconds` of audio via AudioCaptureService, write to a CAF/WAV, then finish.
    func record(seconds: TimeInterval = 5) {
        guard recordTask == nil else { return }

        state = "Recording…"
        lastFileURL = nil

        recordTask = Task {
            do {
                let stream = try capture.start()

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("mic-\(UUID().uuidString).caf")

                var file: AVAudioFile? = nil
                var framesWritten: Int64 = 0
                let targetFrames = Int64(48_000 * seconds)

                for await frame in stream {
                    if file == nil {
                        file = try AVAudioFile(forWriting: url, settings: frame.buffer.format.settings)
                    }
                    try file?.write(from: frame.buffer)
                    framesWritten += Int64(frame.buffer.frameLength)
                    if framesWritten >= targetFrames { break }
                }

                capture.stop()

                await MainActor.run {
                    self.lastFileURL = url
                    self.state = "Recorded: \(seconds)s"
                }
            } catch {
                await MainActor.run { self.state = "Record error: \(error.localizedDescription)" }
            }

            await MainActor.run { self.recordTask = nil }
        }
    }

    func play() {
        guard let url = lastFileURL else {
            state = "No file to play"
            return
        }

        do {
            let s = AVAudioSession.sharedInstance()
            try s.setCategory(.playback)
            try s.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            state = "Playing…"
        } catch {
            state = "Play error: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        state = "Idle"
    }
}
