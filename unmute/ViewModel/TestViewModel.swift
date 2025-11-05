//
//  TestViewModel.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import AVFoundation
import Foundation

@Observable
final class TestViewModel {

    private let audio = AvAudioService()
    public let transcriber = LocalTranscriberService()
    var renderedTranscript: AttributedString {
            transcriber.finalizedTranscript + transcriber.volatileTranscript
        }

    var isRunning = false

    func start() async throws {
        transcriber.finalizedTranscript = ""
        transcriber.volatileTranscript = ""
        isRunning = true
        try await transcriber.setUpTranscriber()
        
        // Audio setup now runs asynchronously to prevent UI blocking
        for await input in try await audio.start()  {
            try await self.transcriber.streamAudioToTranscriber(input.buffer)
        }
        
    }

    func stop() async throws {
        audio.stop()
        try await transcriber.finishTranscribing()
        isRunning = false
        
        // Keep caption content after stopping for review
    }

}
