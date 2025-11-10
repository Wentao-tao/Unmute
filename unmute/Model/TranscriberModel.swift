//
//  TranscriberModel.swift
//  unmute
//
//  Created by Wentao Guo on 21/10/25.
//

import Foundation
import SwiftData

/// Time range for a transcription segment
struct Time_sx: Codable {
    let start_ms: Int
    let end_ms: Int
}

/// Single transcription line with speaker and time information
@Model
final class TranscriptionLine {
    var text: String
    var speakerId: Int
    var speakerName: String
    var startMs: Int
    var endMs: Int
    var timestamp: Date
    
    @Relationship(inverse: \TranscriptionSession.lines)
    var session: TranscriptionSession?
    
    init(text: String, speakerId: Int, speakerName: String, startMs: Int, endMs: Int, timestamp: Date = Date()) {
        self.text = text
        self.speakerId = speakerId
        self.speakerName = speakerName
        self.startMs = startMs
        self.endMs = endMs
        self.timestamp = timestamp
    }
}

/// Transcription session containing multiple lines
@Model
final class TranscriptionSession {
    var sessionDate: Date
    var sessionTitle: String
    
    @Relationship(deleteRule: .cascade)
    var lines: [TranscriptionLine] = []
    
    init(sessionDate: Date = Date(), sessionTitle: String = "") {
        self.sessionDate = sessionDate
        self.sessionTitle = sessionTitle.isEmpty ? "Session \(DateFormatter.localizedString(from: sessionDate, dateStyle: .short, timeStyle: .short))" : sessionTitle
    }
}

/// In-memory model for current transcription session
@Observable
class TranscriberModel {
    
    // MARK: - Properties
    
    /// Array of transcribed text lines
    var textLines: [String] = []
    
    /// Array of speaker IDs corresponding to each text line
    var speakers: [Int] = []
    
    /// Array of time ranges for each line
    var times: [Time_sx] = []
    
    /// Array of speaker names for each line
    var name: [String] = []
    
    // MARK: - Methods
    
    /// Adds a new transcription line with its speaker information.
    /// - Parameter item: Dictionary containing "text" (String) and "speaker" (Int) keys
    func add(_ item: [String: Any]) {
        textLines.append(item["text"]! as! String)
        speakers.append(item["speaker"]! as! Int)
    }
    
    /// Appends text to the last line if the speaker matches, otherwise adds a new line.
    /// - Parameters:
    ///   - text: The text to add or append
    ///   - speaker: The speaker ID
    ///   - forceNewLine: If true, always create a new line even for the same speaker
    ///   - time: Time range for this segment
    func appendOrAdd(text: String, speaker: Int, forceNewLine: Bool = false, time: Time_sx) {
        guard !text.isEmpty else { return }
        
        if forceNewLine || speakers.isEmpty || speakers.last != speaker {
            textLines.append(text)
            speakers.append(speaker)
            times.append(time)
            name.append(String(speaker))
        } else {
            let lastIndex = textLines.count - 1
            textLines[lastIndex] += text
            times[lastIndex] = Time_sx(
                start_ms: times[lastIndex].start_ms,
                end_ms: time.end_ms
            )
        }
    }
    
    /// Updates the name for all instances of a specific speaker ID
    /// - Parameters:
    ///   - name: New name to assign
    ///   - id: Speaker ID to update
    func updateName(name: String, id: Int) {
        for i in speakers.indices {
            if speakers[i] == id {
                self.name[i] = name
            }
        }
    }
    
    /// Saves the current session to SwiftData asynchronously
    /// - Parameter modelContext: SwiftData model context
    /// - Returns: The saved TranscriptionSession
    @MainActor
    func saveSession(to modelContext: ModelContext, title: String = "") async -> TranscriptionSession {
        let session = TranscriptionSession(sessionDate: Date(), sessionTitle: title)
        
        // Build session in memory first (fast)
        for i in 0..<textLines.count {
            let line = TranscriptionLine(
                text: textLines[i],
                speakerId: speakers[i],
                speakerName: name[i],
                startMs: times[i].start_ms,
                endMs: times[i].end_ms
            )
            session.lines.append(line)
            modelContext.insert(line)
        }
        
        modelContext.insert(session)
        
        // Save to disk asynchronously (avoid blocking UI)
        do {
            try modelContext.save()
        } catch {
            print("❌ Save Session: Failed to save session: \(error.localizedDescription)")
        }
        
        return session
    }
    
    /// Clears all transcription data
    func clear() {
        textLines.removeAll()
        speakers.removeAll()
        times.removeAll()
        name.removeAll()
    }
}
