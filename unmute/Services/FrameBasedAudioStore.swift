//
//  FrameBasedAudioStore.swift
//  unmute
//
//  Frame-based audio storage for precise timestamp alignment
//

import AVFoundation

/// Stores audio samples with frame-based indexing for accurate time-range extraction
final class FrameBasedAudioStore {
    // MARK: - Properties
    
    /// Linear array storing all audio samples
    private var audioData: [Float] = []
    
    /// Sample rate (16kHz)
    private let sampleRate: Double = 16_000
    
    /// Maximum retention duration in seconds
    private let maxSeconds: Double
    
    /// Total frames received since recording started (accumulative counter)
    private var totalFramesReceived: Int = 0
    
    /// Thread-safe queue for concurrent access
    private let queue = DispatchQueue(label: "audio.framebased.store")
    
    // MARK: - Initialization
    
    /// Initialize the audio store
    /// - Parameter maxSeconds: Maximum audio duration to retain (default 300 seconds / 5 minutes)
    init(maxSeconds: Double = 300) {
        self.maxSeconds = maxSeconds
        let capacity = Int(sampleRate * maxSeconds)
        audioData.reserveCapacity(capacity)
    }
    
    // MARK: - Public Methods
    
    /// Append audio data to the store
    /// - Parameter buffer: 16kHz mono Float32 PCM buffer
    func append(buffer: AVAudioPCMBuffer) {
        queue.async {
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            
            // Append to array
            let bufferPointer = UnsafeBufferPointer(start: channelData, count: frameCount)
            self.audioData.append(contentsOf: bufferPointer)
            self.totalFramesReceived += frameCount
            
            // Maintain maximum capacity (keep most recent audio)
            self.compactIfNeeded()
        }
    }
    
    /// Extract audio for a specific time range
    /// - Parameters:
    ///   - startMs: Start time in milliseconds (relative to recording start)
    ///   - endMs: End time in milliseconds (relative to recording start)
    /// - Returns: Extracted audio buffer, or nil if extraction fails
    func slice(startMs: Int, endMs: Int) -> AVAudioPCMBuffer? {
        return queue.sync {
            // Convert milliseconds to frame numbers
            let startFrame = msToFrames(startMs)
            let endFrame = msToFrames(endMs)
            
            guard endFrame > startFrame else {
                return nil
            }
            
            // Calculate positions relative to current buffer
            let currentOffset = totalFramesReceived - audioData.count
            let relativeStart = startFrame - currentOffset
            let relativeEnd = endFrame - currentOffset
            
            // Check if requested range is available
            guard relativeStart >= 0 else {
                return nil  // Audio already expired (too old)
            }
            
            guard relativeEnd <= audioData.count else {
                return nil  // Audio not yet available (in future)
            }
            
            let actualStart = max(0, relativeStart)
            let actualEnd = min(audioData.count, relativeEnd)
            
            guard actualEnd > actualStart else {
                return nil
            }
            
            // Create output buffer
            let frameCount = actualEnd - actualStart
            guard let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            ),
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(frameCount)
            ) else {
                return nil
            }
            
            buffer.frameLength = AVAudioFrameCount(frameCount)
            
            // Copy data
            guard let dst = buffer.floatChannelData?[0] else { return nil }
            for i in 0..<frameCount {
                dst[i] = audioData[actualStart + i]
            }
            
            return buffer
        }
    }
    
    // MARK: - Private Methods
    
    /// Remove old data to maintain maximum duration limit
    private func compactIfNeeded() {
        let maxFrames = Int(sampleRate * maxSeconds)
        if audioData.count > maxFrames {
            let removeCount = audioData.count - maxFrames
            audioData.removeFirst(removeCount)
        }
    }
    
    /// Convert milliseconds to frame count
    /// - Parameter ms: Time in milliseconds
    /// - Returns: Frame count
    private func msToFrames(_ ms: Int) -> Int {
        return Int(Double(ms) / 1000.0 * sampleRate)
    }
    
    /// Convert frame count to milliseconds
    /// - Parameter frames: Frame count
    /// - Returns: Time in milliseconds
    private func framesToMs(_ frames: Int) -> Int {
        return Int(Double(frames) / sampleRate * 1000.0)
    }
}
