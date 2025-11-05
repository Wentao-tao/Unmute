//
//  TTSService.swift
//  unmute
//
//  Created by Wentao Guo on 04/11/25.
//

@preconcurrency import AVFoundation

/// Text-to-Speech service for converting text to speech output
/// - Note: AVSpeechSynthesizer automatically manages audio session, no manual configuration needed
final class TTSService: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {
    private let speaker = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        speaker.delegate = self
        // AVSpeechSynthesizer handles audio session automatically - no manual config needed
    }
    
    /// Speak the given text using Text-to-Speech
    /// - Parameter text: The text to be spoken
    @MainActor
    func speak(text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // AVSpeechSynthesizer automatically manages audio session
        let speech = AVSpeechUtterance(string: text)
        speech.voice = AVSpeechSynthesisVoice(language: "en-US")
        speech.rate = 0.5
        speech.pitchMultiplier = 1.0
        speaker.speak(speech)
    }
    
    /// Stop speaking immediately
    @MainActor
    func stop() {
        speaker.stopSpeaking(at: .immediate)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    }
}
