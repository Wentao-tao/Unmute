//
//  LocalRecogniseService.swift
//  unmute
//
//  Created by Wentao Guo on 07/10/25.
//

import AVFAudio
import Speech

struct ResultOld {
    let text: String
    let isFinal: Bool
}

final class LocalRecogniseServiceOld {

    private let recognizer: SFSpeechRecognizer
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var feedingTask: Task<Void, Never>?
    private var speechFormat: AVAudioFormat?
    private var avConverter: AVAudioConverter?

    init(locale: Locale = Locale(identifier: "en-US")) {
        guard let r = SFSpeechRecognizer(locale: locale) else {
            fatalError("Unsupported locale: \(locale.identifier)")
        }
        self.recognizer = r
    }

    public func start(
        frams: AsyncStream<AudioFrame>,
        offline: Bool = false,
        onResult: @escaping (ResultOld) -> Void,
        onFinish: @escaping (Error?) -> Void
    ) throws {

        requestSpeechPermissionold { b in
            print(b)
        }
        self.request = SFSpeechAudioBufferRecognitionRequest()
        self.request?.shouldReportPartialResults = true
        self.request?.requiresOnDeviceRecognition = offline

        self.task = recognizer.recognitionTask(with: self.request!) {
            result,
            error in
            if let r = result {

                onResult(
                    .init(
                        text: r.bestTranscription.formattedString,
                        isFinal: r.isFinal
                    )
                )

            }
            if let error = error {
                Task { @MainActor in
                    onFinish(error)
                }
            } else if result?.isFinal == true {
                Task { @MainActor in
                    onFinish(nil)
                }
            }
        }

        self.feedingTask = Task.detached(priority: .userInitiated) {
            [weak self] in
            guard let self else { return }

            do {
                for await frame in frams {
                    try Task.checkCancellation()
                    if self.speechFormat == nil {
                        self.speechFormat = AVAudioFormat(
                            commonFormat: .pcmFormatFloat32,
                            sampleRate: 44_100,
                            channels: 1,
                            interleaved: false
                        )
                        if let sf = self.speechFormat {
                            self.avConverter = AVAudioConverter(
                                from: frame.buffer.format,
                                to: sf
                            )
                        }
                    }

                    guard
                        let outBuf = AVAudioPCMBuffer(
                            pcmFormat: speechFormat!,
                            frameCapacity: frame.buffer.frameLength
                        )
                    else { continue }

                    var convError: NSError?
                    let ib: AVAudioConverterInputBlock = { _, status in
                        status.pointee = .haveData
                        return frame.buffer
                    }
                    self.avConverter?.convert(
                        to: outBuf,
                        error: &convError,
                        withInputFrom: ib
                    )
                    if convError == nil {
                        self.request?.append(outBuf)
                    } else {
                        print("Speech convert error:", convError!)
                    }

                }
                self.request?.endAudio()
            } catch {
                self.request?.endAudio()
            }
        }

    }

    public func stop() {
        self.request?.endAudio()
        feedingTask?.cancel()
        task?.cancel()

        feedingTask = nil
        request = nil
        task = nil
        avConverter = nil
        speechFormat = nil
    }

    func requestSpeechPermissionold(completion: @escaping (Bool) -> Void) {
        let st = SFSpeechRecognizer.authorizationStatus()
        if st != .notDetermined {
            completion(st == .authorized)
            return
        }
        SFSpeechRecognizer.requestAuthorization { status in

            DispatchQueue.main.async { completion(status == .authorized) }
        }
    }

}
