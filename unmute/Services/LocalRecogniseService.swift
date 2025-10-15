//
//  LocalRecogniseService.swift
//  unmute
//
//  Created by Wentao Guo on 13/10/25.
//

import AVFoundation
import Speech

public struct Result {
    public let text: AttributedString
    public let isFinal: Bool
}

public final class LocalRecogniseService {
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?

    private var inputStream: AsyncStream<AnalyzerInput>?
    private var inputCont: AsyncStream<AnalyzerInput>.Continuation?

    private var consumerTask: Task<Void, Never>?
    private var producerTask: Task<Void, Never>?

    private var bestFormat: AVAudioFormat?
    private var converter: AVAudioConverter?

    public init() {}

    public func start(
        frames: AsyncStream<AudioFrame>,
        locale: Locale,
        preset: SpeechTranscriber.Preset = .timeIndexedProgressiveTranscription,
        onResult: @escaping (Result) -> Void,
        onFinish: @escaping (Error?) -> Void
    ) async throws {


        let granted = await requestSpeechPermissionAsync()
        if !granted {
            onFinish(
                NSError(
                    domain: "unmute",
                    code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Speech recognition is not allowed."
                    ]
                )
            )
            return
        }

        self.transcriber = SpeechTranscriber(locale: locale, preset: preset)
        self.analyzer = SpeechAnalyzer(modules: [self.transcriber!])

        do {
            try await ensureModel(transcriber: transcriber!, locale: locale)

        } catch let error as TranscriptionError {
            print(error)
            onFinish(
                NSError(
                    domain: "unmute",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: error.descriptionString
                    ]
                )
            )
            return
        } catch {
            onFinish(error)
            return
        }

        self.bestFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [self.transcriber!])

        self.inputStream = AsyncStream<AnalyzerInput>(
            bufferingPolicy: .bufferingNewest(8)
        ) { [weak self] cont in
            self?.inputCont = cont
            cont.onTermination = { [weak analyzer = self?.analyzer] _ in
                Task {
                    try? await analyzer?.finalizeAndFinishThroughEndOfInput()
                }
            }

        }

        if let inputStream {

            try await self.analyzer!.start(inputSequence: inputStream)
        }

        consumerTask = Task.detached { [weak self] in
            guard let self, let transcriber = self.transcriber else { return }
            do {
                for try await result in transcriber.results {
                    onResult(.init(text: result.text, isFinal: result.isFinal))
                }
                onFinish(nil)
            } catch {
                onFinish(error)
            }

        }

        producerTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                for await frame in frames {
                    try Task.checkCancellation()

                    if self.bestFormat == nil {
                        self.bestFormat =
                            await SpeechAnalyzer.bestAvailableAudioFormat(
                                compatibleWith: [self.transcriber!],
                                considering: frame.buffer.format
                            )
                    }

                    let targetFormat = self.bestFormat ?? frame.buffer.format

                    let outBuf: AVAudioPCMBuffer
                    if frame.buffer.format != targetFormat {
                        if self.converter == nil
                            || self.converter?.outputFormat != targetFormat
                        {
                            self.converter = AVAudioConverter(
                                from: frame.buffer.format,
                                to: targetFormat
                            )
                            self.converter?.primeMethod = .none
                        }
                        guard
                            let tmp = AVAudioPCMBuffer(
                                pcmFormat: targetFormat,
                                frameCapacity: frame.buffer.frameLength
                            )
                        else { continue }

                        var error: NSError?
                        let inputblock: AVAudioConverterInputBlock = {
                            _,
                            status in
                            status.pointee = .haveData
                            return frame.buffer
                        }
                        self.converter?.convert(
                            to: tmp,
                            error: &error,
                            withInputFrom: inputblock
                        )
                        if let error {
                            print("convert error:", error)
                            continue
                        }
                        outBuf = tmp
                    } else {
                        outBuf = frame.buffer
                    }
                    let input = AnalyzerInput(buffer: outBuf)
                    self.inputCont?.yield(input)

                }
                try await self.analyzer?.finalizeAndFinishThroughEndOfInput()
            } catch {
                print(error)
                try? await self.analyzer?.finalizeAndFinishThroughEndOfInput()
            }
        }

    }

    public func stop() async {
        inputCont?.finish()
        inputCont = nil

        producerTask?.cancel()
        producerTask = nil

        try? await analyzer?.finalizeAndFinishThroughEndOfInput()

        consumerTask?.cancel()
        consumerTask = nil

        converter = nil
        bestFormat = nil
        transcriber = nil
        analyzer = nil
    }

    private func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        let st = SFSpeechRecognizer.authorizationStatus()
        if st != .notDetermined {
            completion(st == .authorized)
            return
        }
        SFSpeechRecognizer.requestAuthorization { status in

            DispatchQueue.main.async { completion(status == .authorized) }
        }
    }
    
    private func requestSpeechPermissionAsync() async -> Bool {
        let st = SFSpeechRecognizer.authorizationStatus()
        if st != .notDetermined {
            return st == .authorized
        }
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    public enum TranscriptionError: Error {
        case couldNotDownloadModel
        case failedToSetupRecognitionStream
        case invalidAudioDataType
        case localeNotSupported
        case noInternetForModelDownload
        case audioFilePathNotFound

        var descriptionString: String {
            switch self {

            case .couldNotDownloadModel:
                return "Could not download the model."
            case .failedToSetupRecognitionStream:
                return "Could not set up the speech recognition stream."
            case .invalidAudioDataType:
                return "Unsupported audio format."
            case .localeNotSupported:
                return "This locale is not yet supported by SpeechAnalyzer."
            case .noInternetForModelDownload:
                return
                    "The model could not be downloaded because the user is not connected to internet."
            case .audioFilePathNotFound:
                return "Couldn't write audio to file."
            }
        }
    }

    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale)
        async throws
    {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }

        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }

    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(
            locale.identifier(.bcp47)
        )
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(
            locale.identifier(.bcp47)
        )
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(
            supporting: [module])
        {
            try await downloader.downloadAndInstall()
        }
    }

    func releaseLocales() async {
        let reserved = await AssetInventory.reservedLocales
        for locale in reserved {
            await AssetInventory.release(reservedLocale: locale)
        }
    }
}
