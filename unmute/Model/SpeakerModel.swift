//
//  SpeakerModel.swift
//  unmute
//
//  Created by Wentao Guo on 28/10/25.
//

import AVFoundation
import Accelerate

/// Represents a speaker's voice profile with their name and voice embeddings
struct SpeakerProfile: Codable {
    var name: String
    var embeddings: [[Float]]
}

/// Manages speaker profiles and provides enrollment and identification capabilities
final class SpeakerRegistry {
    private(set) var profiles: [SpeakerProfile] = []
    private let url: URL

    /// Initialize the speaker registry with persistent storage
    /// - Parameter filename: The JSON file name for storing speaker profiles
    init(filename: String = "speakers.json") {
        let doc = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        self.url = doc.appendingPathComponent(filename)
        load()
    }

    /// Enroll a speaker with a new voice embedding (no validation)
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - embedding: Voice embedding vector
    func enroll(name: String, embedding: [Float]) {
        if let idx = profiles.firstIndex(where: { $0.name == name }) {
            profiles[idx].embeddings.append(embedding)
        } else {
            profiles.append(SpeakerProfile(name: name, embeddings: [embedding]))
        }
        save()
    }
    
    /// Enroll a speaker with quality validation (used for auto-learning to prevent voiceprint contamination)
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - embedding: Voice embedding vector
    ///   - minSimilarity: Minimum similarity threshold (default 0.85, stricter than identification threshold)
    /// - Returns: True if enrollment succeeded, false if quality validation failed
    func enrollWithValidation(
        name: String,
        embedding: [Float],
        minSimilarity: Float = 0.85
    ) -> Bool {
        if let idx = profiles.firstIndex(where: { $0.name == name }) {
            let profile = profiles[idx]
            
            // Calculate similarity between new sample and all existing samples
            let similarities = profile.embeddings.map { cosine($0, embedding) }
            let avgSimilarity = similarities.reduce(0, +) / Float(similarities.count)
            let minSim = similarities.min() ?? 0
            
            // Core validation: both average and minimum similarity must meet threshold
            if avgSimilarity >= minSimilarity && minSim >= minSimilarity - 0.05 {
                profiles[idx].embeddings.append(embedding)
                save()
                return true
            } else {
                // Reject sample - likely misidentification or different speaker
                return false
            }
        } else {
            // First enrollment - no existing samples to compare against
            profiles.append(SpeakerProfile(name: name, embeddings: [embedding]))
            save()
            return true
        }
    }

    /// Identify a speaker from a voice embedding
    /// - Parameters:
    ///   - embedding: Voice embedding vector to identify
    ///   - threshold: Minimum similarity score required for positive identification (default 0.80)
    /// - Returns: Tuple of (speaker name, similarity score) if identified, nil otherwise
    func identify(embedding: [Float], threshold: Float = 0.80) -> (
        name: String, score: Float
    )? {
        guard !profiles.isEmpty else {
            return nil
        }
        
        var best: (String, Float)? = nil
        for p in profiles {
            let scores = p.embeddings.map { cosine($0, embedding) }
            let s = scores.max() ?? -1
            
            if best == nil || s > best!.1 { best = (p.name, s) }
        }
        
        if let b = best {
            if b.1 >= threshold {
                return b
            }
        }
        
        return nil
    }
    
    /// Clear all speaker profiles from registry
    func clear() {
        profiles.removeAll()
        save()
    }

    /// Calculate cosine similarity between two embedding vectors
    /// - Parameters:
    ///   - a: First embedding vector
    ///   - b: Second embedding vector
    /// - Returns: Cosine similarity score (0.0 to 1.0)
    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        let n = min(a.count, b.count)
        var dot: Float = 0
        var na: Float = 0
        var nb: Float = 0
        for i in 0..<n {
            let x = a[i]
            let y = b[i]
            dot += x * y
            na += x * x
            nb += y * y
        }
        let denom = (na.squareRoot() * nb.squareRoot())
        return denom > 0 ? dot / denom : 0
    }

    /// Save speaker profiles to persistent storage
    private func save() {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: url)
        } catch {
            // Silently fail - persistence is not critical for runtime operation
        }
    }

    /// Load speaker profiles from persistent storage
    private func load() {
        do {
            let data = try Data(contentsOf: url)
            profiles = try JSONDecoder().decode(
                [SpeakerProfile].self,
                from: data
            )
        } catch {
            profiles = []
        }
    }
}
