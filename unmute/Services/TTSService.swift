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
    func speak(text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // AVSpeechSynthesizer must be called on main thread
        Task { @MainActor in
            // Activate audio session for playback
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [])
                try session.setActive(true)
            } catch {
                print("❌ TTS: Failed to configure audio session: \(error)")
            }
            
            let speech = AVSpeechUtterance(string: text)
            speech.voice = AVSpeechSynthesisVoice(language: "en-US")
            speech.rate = 0.5
            speech.pitchMultiplier = 1.0
            self.speaker.speak(speech)
        }
    }
    
    /// Stop speaking immediately
    func stop() {
        Task { @MainActor in
            speaker.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    }
}
