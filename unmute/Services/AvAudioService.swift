//
//  AvAudioService.swift
//  unmute
//
//  Created by Wentao Guo on 03/10/25.
//

import AVFAudio
import AVFoundation
import Foundation

/// A single ~20 ms audio frame (48 kHz, mono, Float32) and its timestamp.
public struct AudioFrame {
    public let buffer: AVAudioPCMBuffer
    public let timestamp: AVAudioTime
}

/// Captures mic audio through Apple's voice-processing chain (AEC/NS/AGC),
/// converts it to 48 kHz / mono / Float32, and exposes frames as an AsyncStream.
public final class AvAudioService {

    // MARK: - Private state

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var outFormat: AVAudioFormat!
    private var continuation: AsyncStream<AudioFrame>.Continuation?

    private var isRunning = false

    public init() {}

    deinit { stop() }

    // MARK: - Public API

    /// Start capturing and return an async stream of ~20 ms frames.
    public func start() throws -> AsyncStream<AudioFrame> {
        guard !isRunning else { return makeStream() }

        try setupAudioSession()
        try configureEngineAndTap()
        isRunning = true
        return makeStream()
    }

    /// Stop capturing and release audio resources.
    public func stop() {
        guard isRunning else { return }

        // Remove tap and stop engine
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        // Close the async stream
        continuation?.finish()
        continuation = nil

        // Release resources
        converter = nil
        outFormat = nil
        isRunning = false

        // Deactivate the audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Session + Engine

    /// Configure AVAudioSession to enable voice processing (AEC/NS/AGC).
    private func setupAudioSession() throws {
        let s = AVAudioSession.sharedInstance()

        // Record + play (speaker), allow Bluetooth headsets.
        try s.setCategory(.playAndRecord)

        // Critical: voice chat mode enables echo cancellation, noise suppression, AGC.
        try s.setMode(.voiceChat)

        // Prefer 48 kHz
        try? s.setPreferredSampleRate(16_000)
        
        // Prefer mono
        try? s.setPreferredInputNumberOfChannels(1)
        
        // Prefer 20ms buffer
        try? s.setPreferredIOBufferDuration(0.02)

        // Must activate before starting the engine
        try s.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Prepare engine, install tap on inputNode, and start the engine.
    private func configureEngineAndTap() throws {
        let input = engine.inputNode

        // Use the device's current input format for the tap (most stable).
        let inFmt = input.inputFormat(forBus: 0)

        // Our unified target format: 48 kHz / mono / Float32 (non-interleaved).
        guard let outFmt = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false)
        else {
            throw NSError(domain: "Audio", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create output format"])
        }
        outFormat = outFmt

        // Converter from the device input format -> our target format.
        guard let conv = AVAudioConverter(from: inFmt, to: outFmt) else {
            throw NSError(domain: "Audio", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to create audio converter"])
        }
        converter = conv

        // Install a tap; use 0 to let system choose appropriate buffer size
        input.installTap(onBus: 0, bufferSize: 0, format: inFmt) {
            [weak self] buf, time in
            guard let self, let converter = self.converter,
                let outFormat = self.outFormat
            else { return }

            // Dynamically calculate output buffer size
            let inputFrames = buf.frameLength
            let ratio = outFormat.sampleRate / buf.format.sampleRate
            let outputCapacity = AVAudioFrameCount(Double(inputFrames) * ratio + 1)
            
            // Allocate target buffer
            guard let outBuf = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: outputCapacity)
            else { return }

            // Provide the tap buffer to the converter when requested.
            var err: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buf
            }

            // Convert inFmt -> outFormat
            let status = converter.convert(to: outBuf, error: &err, withInputFrom: inputBlock)
            guard err == nil, status != .error, outBuf.frameLength > 0 else { return }

            // Push the converted frame into the async stream.
            _ = self.continuation?.yield(AudioFrame(buffer: outBuf, timestamp: time))
            VoiceService.shared.audioStore.append(buffer: outBuf)

        }

        engine.prepare()
        try engine.start()
    }

    // MARK: - AsyncStream plumbing

    /// Create an AsyncStream and keep its continuation so we can yield/finish later.
    private func makeStream() -> AsyncStream<AudioFrame> {
        AsyncStream<AudioFrame>(bufferingPolicy: .bufferingNewest(8)) {
            [weak self] cont in
            guard let self else { return }
            self.continuation = cont

            // If consumer cancels/finishes, stop the engine cleanly.
            cont.onTermination = { [weak self] _ in
                self?.stop()
            }
        }
    }
}
