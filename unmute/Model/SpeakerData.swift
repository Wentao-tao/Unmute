//
//  SpeakerData 2.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 07/11/25.
//


import Foundation
import SwiftUI

struct SpeakerData: Identifiable {
    let id = UUID()
    var name: String
    var message: String
    var symbol: String
    var color: Color

    // Optional backend metadata
    var speakerID: String?
    var duration: Double?
    var timestamp: TimeInterval?
    var isPersistent: Bool = false

    private static let availableSymbols = [
        "person.fill",
        "person.wave.2.fill",
        "person.2.fill",
        "music.mic",
        "person.crop.circle",
        "person.fill.turn.down",
        "person.text.rectangle.fill",
        "figure.wave"
    ]

    private static let availableColors: [Color] = [
        .violet6, .yellow1, .red6, .blue, .green, .orange, .pink, .indigo
    ]

    static func create(name: String, message: String) -> SpeakerData {
        SpeakerData(
            name: name,
            message: message,
            symbol: availableSymbols.randomElement() ?? "person.fill",
            color: availableColors.randomElement() ?? .violet6
        )
    }

}
