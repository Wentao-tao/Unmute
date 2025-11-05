//
//  ONNXEmbeddingExtractor.swift
//  unmute
//
//  ONNX Runtime embedding extractor using SpeechBrain ECAPA-TDNN model
//

import Foundation
@preconcurrency import AVFoundation
import onnxruntime_objc

/// Extracts speaker embeddings using ONNX Runtime and SpeechBrain ECAPA-TDNN model
/// - Note: Marked as @unchecked Sendable because thread safety is manually ensured via sessionQueue
final class ONNXEmbeddingExtractor: @unchecked Sendable {
    private var env: ORTEnv?
    private var session: ORTSession?
    private let fbankExtractor = Fbank80Extractor()
    private let sessionQueue = DispatchQueue(label: "onnx.inference", qos: .userInitiated)
    private var isInitialized = false
    private var initializationTask: Task<Void, Never>?
    
    init() {
        // Model loading moved to lazy initialization to prevent blocking main thread
    }
    
    /// Ensure ONNX model is initialized (lazy loading, only once)
    /// - Note: Safe to call multiple times - initialization happens only once
    private func ensureInitialized() async {
        // If there's an ongoing initialization, wait for it
        if let task = initializationTask {
            await task.value
            return
        }
        
        // If already initialized, return immediately
        guard !isInitialized else { return }
        
        // Create and cache the initialization task
        let task = Task {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.sessionQueue.async { [weak self] in
                    guard let self = self, !self.isInitialized else {
                        continuation.resume()
                        return
                    }
                    
                    do {
                        // Create ONNX Runtime environment
                        self.env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
                        
                        guard let env = self.env else {
                            print("❌ ONNX: Failed to create environment")
                            continuation.resume()
                            return
                        }
                        
                        // Load model file
                        guard let modelPath = Bundle.main.path(forResource: "ecapa_tdnn_embedding", ofType: "onnx") else {
                            print("❌ ONNX: Model file not found")
                            continuation.resume()
                            return
                        }
                        
                        // Configure session options
                        let options = try ORTSessionOptions()
                        try options.setIntraOpNumThreads(2)
                        
                        // Create inference session (this is the heavy operation)
                        self.session = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
                        self.isInitialized = true
                    } catch {
                        print("❌ ONNX initialization failed: \(error)")
                    }
                    
                    continuation.resume()
                }
            }
        }
        
        initializationTask = task
        await task.value
    }
    
    /// Extract speaker embedding from audio buffer asynchronously
    /// - Parameter buffer: 16kHz mono audio buffer
    /// - Returns: L2-normalized embedding vector, or nil if extraction fails
    /// - Note: Runs on background queue to avoid blocking main thread
    func embed(from buffer: AVAudioPCMBuffer) async -> [Float]? {
        // Ensure model is initialized (lazy loading on first use)
        await ensureInitialized()
        
        return await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let result = self.performInference(buffer: buffer)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Performs synchronous inference on background queue
    /// - Parameter buffer: 16kHz mono audio buffer
    /// - Returns: L2-normalized embedding vector, or nil if extraction fails
    private func performInference(buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let session = session else {
            return nil
        }
        
        // Extract Fbank80 features
        guard let fbank = fbankExtractor?.makeFbank(from16kMono: buffer) else {
            return nil
        }
        
        let nMels = fbank.count       // 80
        let nFrames = fbank[0].count  // Dynamic length
        
        // Convert to [batch=1, features=80, time=nFrames] format
        var flatData = [Float]()
        flatData.reserveCapacity(nMels * nFrames)
        
        for mel in 0..<nMels {
            flatData.append(contentsOf: fbank[mel])
        }
        
        // Create NSMutableData
        let inputData = NSMutableData(bytes: flatData, length: flatData.count * MemoryLayout<Float>.size)
        
        do {
            // Create input tensor
            let shape: [NSNumber] = [1, NSNumber(value: nMels), NSNumber(value: nFrames)]
            let inputTensor = try ORTValue(
                tensorData: inputData,
                elementType: .float,
                shape: shape
            )
            
            // Run inference
            let outputs = try session.run(
                withInputs: ["fbank": inputTensor],
                outputNames: ["embedding"],
                runOptions: nil
            )
            
            // Extract output
            guard let outputTensor = outputs["embedding"],
                  let outputData = try? outputTensor.tensorData() as Data else {
                return nil
            }
            
            // Convert to Float array
            let embedding = outputData.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self))
            }
            
            // L2 normalization
            let norm = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
            let normalized: [Float]
            if norm > 0 {
                normalized = embedding.map { $0 / norm }
            } else {
                normalized = embedding
            }
            
            return normalized
            
        } catch {
            return nil
        }
    }
}
