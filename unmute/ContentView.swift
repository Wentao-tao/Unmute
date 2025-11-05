//
//  ContentView.swift
//  unmute
//
//  Created by Wentao Guo on 02/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            VStack {
                TestView()
            }
            .padding()
            .navigationTitle("Speech Recognition")
        }
        .onAppear {
            Task { @MainActor in
                // Initialize VoiceService with SwiftData context
                VoiceService.shared.initializeRegistry(with: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            SpeakerProfile.self,
            TranscriptionSession.self,
            TranscriptionLine.self
        ])
}
