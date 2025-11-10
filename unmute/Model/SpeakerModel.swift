//
//  SpeakerModel.swift
//  unmute
//
//  Created by Wentao Guo on 28/10/25.
//

import AVFoundation
import Accelerate
import SwiftData

/// Represents a speaker's voice profile with their name and voice embeddings
@Model
final class SpeakerProfile {
    var name: String
    var embeddings: [[Float]]
    
    init(name: String, embeddings: [[Float]] = []) {
        self.name = name
        self.embeddings = embeddings
    }
}

/// Manages speaker profiles and provides enrollment and identification capabilities
@MainActor
final class SpeakerRegistry: ObservableObject {
    private let modelContext: ModelContext
    @Published private(set) var profiles: [SpeakerProfile] = []
    private var saveTask: Task<Void, Never>?

    /// Initialize the speaker registry with SwiftData context
    /// - Parameter modelContext: SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadProfiles()
    }

    /// Enroll a speaker with a new voice embedding (no validation)
    /// - Parameters:
    ///   - name: Speaker's name
    ///   - embedding: Voice embedding vector
    func enroll(name: String, embedding: [Float]) {
        if let profile = profiles.first(where: { $0.name == name }) {
            profile.embeddings.append(embedding)
        } else {
            let newProfile = SpeakerProfile(name: name, embeddings: [embedding])
            modelContext.insert(newProfile)
            profiles.append(newProfile)
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
        if let profile = profiles.first(where: { $0.name == name }) {
            // Calculate similarity between new sample and all existing samples
            let similarities = profile.embeddings.map { cosine($0, embedding) }
            let avgSimilarity = similarities.reduce(0, +) / Float(similarities.count)
            let minSim = similarities.min() ?? 0
            
            // Core validation: both average and minimum similarity must meet threshold
            if avgSimilarity >= minSimilarity && minSim >= minSimilarity - 0.05 {
                profile.embeddings.append(embedding)
                save()
                return true
            } else {
                // Reject sample - likely misidentification or different speaker
                return false
            }
        } else {
            // First enrollment - no existing samples to compare against
            let newProfile = SpeakerProfile(name: name, embeddings: [embedding])
            modelContext.insert(newProfile)
            profiles.append(newProfile)
            save()
            return true
        }
    }

    /// Identify a speaker from a voice embedding
    /// - Parameters:
    ///   - embedding: Voice embedding vector to identify
    ///   - threshold: Minimum similarity score required for positive identification (default 0.80)
    /// - Returns: Tuple of (speaker name, similarity score) if identified, nil otherwise
    func identify(embedding: [Float], threshold: Float = 0.83) -> (
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
        for profile in profiles {
            modelContext.delete(profile)
        }
        profiles.removeAll()
        saveImmediately()
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

    /// Save changes to SwiftData asynchronously with debounce
    /// This prevents frequent disk I/O from blocking the main thread
    private func save() {
        // Cancel previous save task (debounce)
        saveTask?.cancel()
        
        // Schedule new save with 0.5 second delay
        saveTask = Task {
            // Wait 500ms to batch multiple changes
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            // Perform save asynchronously
            do {
                try self.modelContext.save()
            } catch {
                print("❌ Speaker Registry: Save failed: \(error)")
            }
        }
    }
    
    /// Force immediate save (for critical operations like clear)
    private func saveImmediately() {
        saveTask?.cancel()
        do {
            try modelContext.save()
        } catch {
            print("❌ Speaker Registry: Immediate save failed: \(error)")
        }
    }

    /// Load speaker profiles from SwiftData
    private func loadProfiles() {
        let descriptor = FetchDescriptor<SpeakerProfile>()
        do {
            profiles = try modelContext.fetch(descriptor)
        } catch {
            profiles = []
        }
    }
}
