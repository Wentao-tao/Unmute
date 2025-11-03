//
//  ONNXEmbeddingExtractor.swift
//  unmute
//
//  ONNX Runtime embedding extractor using SpeechBrain ECAPA-TDNN model
//

import Foundation
import AVFoundation
import onnxruntime_objc

/// Extracts speaker embeddings using ONNX Runtime and SpeechBrain ECAPA-TDNN model
final class ONNXEmbeddingExtractor {
    private var env: ORTEnv?
    private var session: ORTSession?
    private let fbankExtractor = Fbank80Extractor()
    private let sessionQueue = DispatchQueue(label: "onnx.inference", qos: .userInitiated)
    
    init() {
        setupSession()
    }
    
    /// Initialize ONNX Runtime session with the model
    private func setupSession() {
        do {
            // Create ONNX Runtime environment
            env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
            
            guard let env = env else {
                return
            }
            
            // Load model file
            guard let modelPath = Bundle.main.path(forResource: "ecapa_tdnn_embedding", ofType: "onnx") else {
                return
            }
            
            // Configure session options
            let options = try ORTSessionOptions()
            try options.setIntraOpNumThreads(2)
            
            // Create inference session
            session = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
            
        } catch {
            // Silent failure - session will be nil and embed() will return nil
        }
    }
    
    /// Extract speaker embedding from audio buffer
    /// - Parameter buffer: 16kHz mono audio buffer
    /// - Returns: L2-normalized embedding vector, or nil if extraction fails
    func embed(from buffer: AVAudioPCMBuffer) -> [Float]? {
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
