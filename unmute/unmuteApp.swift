//
//  unmuteApp.swift
//  unmute
//
//  Created by Wentao Guo on 02/10/25.
//

import SwiftUI
import SwiftData

@main
struct unmuteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            SpeakerProfile.self,
            TranscriptionSession.self,
            TranscriptionLine.self
        ])
    }
}
