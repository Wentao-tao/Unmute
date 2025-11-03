//
//  VoiceService.swift
//  unmute
//
//  Created by Wentao Guo on 27/10/25.
//

import AVFoundation
import Accelerate

/// Extracts voice embeddings from audio buffers using ONNX model
final class EmbeddingExtractor {
    private let onnxExtractor = ONNXEmbeddingExtractor()
    
    /// Extract voice embedding from audio buffer
    /// - Parameter buffer: Audio buffer to process
    /// - Returns: Voice embedding vector, or nil if extraction fails
    func embed(from buffer: AVAudioPCMBuffer) -> [Float]? {
        return onnxExtractor.embed(from: buffer)
    }
}

/// Main service for speaker recognition operations
final class VoiceService {
    static let shared = VoiceService()

    var audioStore = FrameBasedAudioStore(maxSeconds: 60)
    let registry = SpeakerRegistry()
    let extractor = EmbeddingExtractor()

    /// Enroll a speaker from a single audio segment
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - startMs: Start time in milliseconds
    ///   - endMs: End time in milliseconds
    /// - Returns: True if enrollment succeeded, false otherwise
    func enroll(name: String, startMs: Int, endMs: Int) -> Bool {
        guard
            let buf = audioStore.slice(
                startMs: startMs,
                endMs: endMs,
            ),
            let emb = extractor.embed(from: buf)
        else { return false }
        registry.enroll(name: name, embedding: emb)
        return true
    }
    
    /// Enroll a speaker from multiple concatenated audio segments
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - timeRanges: Array of (start, end) time ranges in milliseconds
    /// - Returns: True if enrollment succeeded, false otherwise
    func enrollMultipleSegments(name: String, timeRanges: [(Int, Int)]) -> Bool {
        guard !timeRanges.isEmpty else { return false }
        
        // Collect audio buffers from all segments
        var buffers: [AVAudioPCMBuffer] = []
        
        for (startMs, endMs) in timeRanges {
            if let buf = audioStore.slice(startMs: startMs, endMs: endMs) {
                buffers.append(buf)
            }
        }
        
        guard !buffers.isEmpty else { return false }
        
        // Concatenate all buffers
        guard let concatenated = concatenateBuffers(buffers) else {
            return false
        }
        
        // Extract embedding
        guard let emb = extractor.embed(from: concatenated) else {
            return false
        }
        
        // Enroll
        registry.enroll(name: name, embedding: emb)
        return true
    }
    
    /// Enroll a speaker with quality validation (for auto-learning to prevent voiceprint contamination)
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - timeRanges: Array of (start, end) time ranges in milliseconds
    ///   - minSimilarity: Minimum similarity threshold for validation
    /// - Returns: True if validation passed and enrollment succeeded, false otherwise
    func enrollMultipleSegmentsWithValidation(
        name: String,
        timeRanges: [(Int, Int)],
        minSimilarity: Float = 0.85
    ) -> Bool {
        guard !timeRanges.isEmpty else { return false }
        
        // Collect audio buffers from all segments
        var buffers: [AVAudioPCMBuffer] = []
        
        for (startMs, endMs) in timeRanges {
            if let buf = audioStore.slice(startMs: startMs, endMs: endMs) {
                buffers.append(buf)
            }
        }
        
        guard !buffers.isEmpty else { return false }
        
        // Concatenate all buffers
        guard let concatenated = concatenateBuffers(buffers) else {
            return false
        }
        
        // Extract embedding
        guard let emb = extractor.embed(from: concatenated) else {
            return false
        }
        
        // Enroll with validation
        return registry.enrollWithValidation(
            name: name,
            embedding: emb,
            minSimilarity: minSimilarity
        )
    }
    
    /// Concatenate multiple audio buffers into a single buffer
    /// - Parameter buffers: Array of audio buffers to concatenate
    /// - Returns: Concatenated audio buffer, or nil if concatenation fails
    private func concatenateBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        guard !buffers.isEmpty else { return nil }
        
        let format = buffers[0].format
        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        
        guard let output = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(totalFrames)
        ) else {
            return nil
        }
        
        output.frameLength = AVAudioFrameCount(totalFrames)
        
        guard let outputData = output.floatChannelData?[0] else {
            return nil
        }
        
        var offset = 0
        for buffer in buffers {
            guard let inputData = buffer.floatChannelData?[0] else { continue }
            let frameCount = Int(buffer.frameLength)
            
            outputData.advanced(by: offset).update(from: inputData, count: frameCount)
            offset += frameCount
        }
        
        return output
    }

    /// Identify a speaker from a single audio segment
    /// - Parameters:
    ///   - startMs: Start time in milliseconds
    ///   - endMs: End time in milliseconds
    /// - Returns: Tuple of (speaker name, similarity score) if identified, nil otherwise
    func identify(startMs: Int, endMs: Int) -> (String, Float)? {
        guard
            let buf = audioStore.slice(
                startMs: startMs,
                endMs: endMs,
            ),
            let emb = extractor.embed(from: buf)
        else { return nil }
        return registry.identify(embedding: emb)
    }
    
    /// Identify a speaker from multiple concatenated audio segments
    /// - Parameter timeRanges: Array of (start, end) time ranges in milliseconds
    /// - Returns: Tuple of (speaker name, similarity score) if identified, nil otherwise
    func identifyMultipleSegments(timeRanges: [(Int, Int)]) -> (String, Float)? {
        guard !timeRanges.isEmpty else { return nil }
        
        // Collect audio buffers from all segments
        var buffers: [AVAudioPCMBuffer] = []
        
        for (startMs, endMs) in timeRanges {
            if let buf = audioStore.slice(startMs: startMs, endMs: endMs) {
                buffers.append(buf)
            }
        }
        
        guard !buffers.isEmpty else { return nil }
        
        // Concatenate all buffers
        guard let concatenated = concatenateBuffers(buffers) else {
            return nil
        }
        
        // Extract embedding
        guard let emb = extractor.embed(from: concatenated) else {
            return nil
        }
        
        // Identify
        return registry.identify(embedding: emb)
    }
}
