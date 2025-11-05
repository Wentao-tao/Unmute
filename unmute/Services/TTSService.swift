//
//  TTSService.swift
//  unmute
//
//  Created by Wentao Guo on 04/11/25.
//

@preconcurrency import AVFoundation

/// Text-to-Speech service for converting text to speech output
final class TTSService: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {
    private let speaker = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        speaker.delegate = self
    }
    
    /// Speak the given text using Text-to-Speech
    /// - Parameter text: The text to be spoken
    @MainActor
    func speak(text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Use .playAndRecord to maintain recording capability during TTS
        // .voiceChat mode provides echo cancellation to prevent TTS from being recorded
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker]
            )
            try session.setActive(true)
        } catch {
            print("❌ TTS: Failed to configure audio session: \(error)")
        }
        
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
