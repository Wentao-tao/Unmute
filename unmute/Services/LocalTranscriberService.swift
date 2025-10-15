//
//  LocalTranscriberService.swift
//  unmute
//
//  Created by Wentao Guo on 15/10/25.
//

import Foundation
import Speech
import SwiftUI

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

@Observable
final class LocalTranscriberService {
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), Error>?

    // The format of the audio.
    var analyzerFormat: AVAudioFormat?

    var converter = BufferConverter()
    var downloadProgress: Progress?

    var volatileTranscript: AttributedString = ""
    var finalizedTranscript: AttributedString = ""

    static let locale = Locale(
        components: .init(
            languageCode: .english,
            script: nil,
            languageRegion: .unitedStates
        )
    )

    init() {
    }

    func setUpTranscriber() async throws {
        let granted = await requestSpeechPermissionAsync()
        if !granted {
            print("need to authorize")
            return
        }

        transcriber = SpeechTranscriber(
            locale: LocalTranscriberService.locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )

        guard let transcriber else {
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        analyzer = SpeechAnalyzer(modules: [transcriber])

        do {
            try await ensureModel(
                transcriber: transcriber,
                locale: LocalTranscriberService.locale
            )
        } catch let error as TranscriptionError {
            print(error)
            return
        }

        self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber])
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()

        guard let inputSequence else { return }

        recognizerTask = Task {
            do {
                for try await case let result in transcriber.results {
                    let text = result.text
                    await MainActor.run {
                        if result.isFinal {
                            finalizedTranscript += text
                            finalizedTranscript += "\n"
                            volatileTranscript = ""

                        } else {
                            volatileTranscript = text
                            volatileTranscript.foregroundColor = .purple
                                .opacity(
                                    0.4
                                )
                        }
                    }
                }
            } catch {
                print("speech recognition failed")
            }
        }

        try await analyzer?.start(inputSequence: inputSequence)
    }

    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder, let analyzerFormat else {
            throw TranscriptionError.invalidAudioDataType
        }

        let converted = try self.converter.convertBuffer(
            buffer,
            to: analyzerFormat
        )
        let input = AnalyzerInput(buffer: converted)

        inputBuilder.yield(input)
    }

    public func finishTranscribing() async throws {
        inputBuilder?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil
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

}

extension LocalTranscriberService {
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
            self.downloadProgress = downloader.progress
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
