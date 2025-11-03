//
//  TranscriberModel.swift
//  unmute
//
//  Created by Wentao Guo on 21/10/25.
//

import Foundation

/// Model class that stores transcription results with speaker information.
/// Maintains parallel arrays of text content and corresponding speaker IDs.

struct Time_sx {
    let start_ms: Int
    let end_ms: Int
}

class TranscriberModel {
    
    // MARK: - Properties
    
    /// Array of transcribed text lines
    var textLines: [String] = []
    
    /// Array of speaker IDs corresponding to each text line
    /// Each speaker ID corresponds to the text line at the same index
    var speakers: [Int] = []
    
    var times: [Time_sx] = []
    
    var name: [String] = []
    
    // MARK: - Methods
    
    /// Adds a new transcription line with its speaker information.
    /// - Parameter item: Dictionary containing "text" (String) and "speaker" (Int) keys
    /// - Warning: This method will crash if the required keys are missing or have wrong types
    func add(_ item: [String: Any]) {
        textLines.append(item["text"]! as! String)
        speakers.append(item["speaker"]! as! Int)
    }
    
    /// Appends text to the last line if the speaker matches, otherwise adds a new line.
    /// This prevents fragmenting continuous speech from the same speaker into multiple lines.
    /// - Parameters:
    ///   - text: The text to add or append
    ///   - speaker: The speaker ID
    ///   - forceNewLine: If true, always create a new line even for the same speaker
    func appendOrAdd(text: String, speaker: Int, forceNewLine: Bool = false, time: Time_sx) {
        guard !text.isEmpty else { return }
        
        // If force new line is true, or speaker is different, create new line
        if forceNewLine || speakers.isEmpty || speakers.last != speaker {
            textLines.append(text)
            speakers.append(speaker)
            times.append(time)
            name.append(String(speaker))
        } else {
            // Same speaker and not forcing new line - append to last line
            let lastIndex = textLines.count - 1
            textLines[lastIndex] += text
            // Update the end time to reflect the extended speech segment
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
    
    /// Clears all transcription data.
    func clear() {
        textLines.removeAll()
        speakers.removeAll()
        times.removeAll()
        name.removeAll()
    }
}
