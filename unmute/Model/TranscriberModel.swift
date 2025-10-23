//
//  TranscriberModel.swift
//  unmute
//
//  Created by Wentao Guo on 21/10/25.
//

import Foundation

/// Model class that stores transcription results with speaker information.
/// Maintains parallel arrays of text content and corresponding speaker IDs.
class TranscriberModel {
    
    // MARK: - Properties
    
    /// Array of transcribed text lines
    var textLines: [String] = []
    
    /// Array of speaker IDs corresponding to each text line
    /// Each speaker ID corresponds to the text line at the same index
    var speakers: [Int] = []
    
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
    func appendOrAdd(text: String, speaker: Int, forceNewLine: Bool = false) {
        guard !text.isEmpty else { return }
        
        // If force new line is true, or speaker is different, create new line
        if forceNewLine || speakers.isEmpty || speakers.last != speaker {
            textLines.append(text)
            speakers.append(speaker)
        } else {
            // Same speaker and not forcing new line - append to last line
            textLines[textLines.count - 1] += text
        }
    }
    
    /// Clears all transcription data.
    func clear() {
        textLines.removeAll()
        speakers.removeAll()
    }
}
