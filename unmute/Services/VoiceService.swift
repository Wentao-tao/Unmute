//
//  VoiceService.swift
//  unmute
//
//  Created by Wentao Guo on 27/10/25.
//

import AVFoundation
import Accelerate
import SwiftData

/// Extracts voice embeddings from audio buffers using ONNX model
final class EmbeddingExtractor {
    private let onnxExtractor = ONNXEmbeddingExtractor()
    
    /// Extract voice embedding from audio buffer asynchronously
    /// - Parameter buffer: Audio buffer to process
    /// - Returns: Voice embedding vector, or nil if extraction fails
    /// - Note: Runs on background queue to avoid blocking main thread
    func embed(from buffer: AVAudioPCMBuffer) async -> [Float]? {
        return await onnxExtractor.embed(from: buffer)
    }
}

/// Main service for speaker recognition operations
final class VoiceService {
    static let shared = VoiceService()

    var audioStore = FrameBasedAudioStore(maxSeconds: 60)
    private var _registry: SpeakerRegistry?
    let extractor = EmbeddingExtractor()
    
    private init() {}
    
    /// Initialize the speaker registry with SwiftData context
    /// - Parameter modelContext: SwiftData model context
    @MainActor
    func initializeRegistry(with modelContext: ModelContext) {
        self._registry = SpeakerRegistry(modelContext: modelContext)
    }
    
    /// Access registry (must be called from main actor context)
    @MainActor
    var registry: SpeakerRegistry? {
        return _registry
    }

    /// Enroll a speaker from a single audio segment
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - startMs: Start time in milliseconds
    ///   - endMs: End time in milliseconds
    /// - Returns: True if enrollment succeeded, false otherwise
    func enroll(name: String, startMs: Int, endMs: Int) async -> Bool {
        guard await MainActor.run(body: { self._registry != nil }) else { return false }
        
        guard let buf = audioStore.slice(startMs: startMs, endMs: endMs) else {
            return false
        }
        
        // Extract embedding asynchronously (prevents UI blocking)
        guard let emb = await extractor.embed(from: buf) else {
            return false
        }
        
        await MainActor.run {
            self._registry?.enroll(name: name, embedding: emb)
    }
        return true
    }
    
    /// Enroll a speaker from multiple concatenated audio segments
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - timeRanges: Array of (start, end) time ranges in milliseconds
    /// - Returns: True if enrollment succeeded, false otherwise
    func enrollMultipleSegments(name: String, timeRanges: [(Int, Int)]) async -> Bool {
        guard await MainActor.run(body: { self._registry != nil }) else { return false }
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
        
        // Extract embedding asynchronously (prevents UI blocking)
        guard let emb = await extractor.embed(from: concatenated) else {
            return false
        }
        
        // Enroll
        await MainActor.run {
            self._registry?.enroll(name: name, embedding: emb)
        }
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
    ) async -> Bool {
        guard await MainActor.run(body: { self._registry != nil }) else { return false }
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
        
        // Extract embedding asynchronously (prevents UI blocking)
        guard let emb = await extractor.embed(from: concatenated) else {
            return false
        }
        
        // Enroll with validation
        return await MainActor.run {
            return self._registry?.enrollWithValidation(
                name: name,
                embedding: emb,
                minSimilarity: minSimilarity
            ) ?? false
        }
    }
    
    /// Concatenate multiple audio buffers into a single buffer
    /// - Parameter buffers: Array of audio buffers to concatenate
    /// - Returns: Concatenated audio buffer, or nil if concatenation fails
    private func concatenateBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        let start = Date()
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
        
        let duration = Date().timeIntervalSince(start) * 1000
        if duration > 10 {  // Only log if > 10ms
        }
        return output
    }

    /// Identify a speaker from a single audio segment
    /// - Parameters:
    ///   - startMs: Start time in milliseconds
    ///   - endMs: End time in milliseconds
    /// - Returns: Tuple of (speaker name, similarity score) if identified, nil otherwise
    func identify(startMs: Int, endMs: Int) async -> (String, Float)? {
        guard await MainActor.run(body: { self._registry != nil }) else { return nil }
        
        guard let buf = audioStore.slice(startMs: startMs, endMs: endMs) else {
            return nil
        }
        
        // Extract embedding asynchronously (prevents UI blocking)
        guard let emb = await extractor.embed(from: buf) else {
            return nil
        }
        
        return await MainActor.run {
            return self._registry?.identify(embedding: emb)
        }
    }
    
    /// Identify a speaker from multiple concatenated audio segments
    /// - Parameter timeRanges: Array of (start, end) time ranges in milliseconds
    /// - Returns: Tuple of (speaker name, similarity score) if identified, nil otherwise
    func identifyMultipleSegments(timeRanges: [(Int, Int)]) async -> (String, Float)? {
        guard await MainActor.run(body: { self._registry != nil }) else { return nil }
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

        // Extract embedding asynchronously (prevents UI blocking)
        guard let emb = await extractor.embed(from: concatenated) else {
            return nil
        }
        
        // Identify
        return await MainActor.run {
            return self._registry?.identify(embedding: emb)
        }
    }
}
