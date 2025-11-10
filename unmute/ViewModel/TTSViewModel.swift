//
//  TTSViewModel.swift
//  unmute
//
//  Created by Wentao Guo on 04/11/25.
//

import Foundation

/// ViewModel for Text-to-Speech functionality
@Observable
final class TTSViewModel {
    private let speaker = TTSService()
    
    /// Speak the given text
    /// - Parameter text: The text to be spoken
    @MainActor
    func speak(_ text: String) {
        speaker.speak(text: text)
    }
    
    /// Stop speaking immediately
    @MainActor
    func stop() {
        speaker.stop()
    }
}
