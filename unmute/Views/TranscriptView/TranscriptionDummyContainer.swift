//
//  TranscriptionDummyContainer.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 05/11/25.
//


import SwiftUI

// MARK: - Dummy Container
struct TranscriptionDummyContainer: View {
    @State private var speakers: [SpeakerData] = []
    @Binding var isRename: Bool
    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(speakers) { speaker in
                            SpeakerBubble(
                                symbol: speaker.symbol,
                                name: speaker.name,
                                message: speaker.message,
                                color: speaker.color,
                                isRename: $isRename
                            )
                            .id(speaker.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 40)
                }
                .onAppear {
                    generateDummySpeakers()
                    
                    // Smooth scroll to bottom
                    if let last = speakers.last {
                        DispatchQueue.main.async {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Dummy Generator with Persistent Color/Icon
    private func generateDummySpeakers() {
        var profileCache: [String: (String, Color)] = [:]
        var list: [SpeakerData] = []
        
        let dummyMessages: [String] = [
            "Hey everyone, can we go over the project timeline again? I think we’re missing a few deliverables in phase two.",
            "Right, I just uploaded the latest design mockups to the shared folder — could you all take a look before tomorrow?",
            "Honestly, I feel like we’re moving a bit too fast. We might want to validate the user flow before adding new features.",
            "Yes, I’ve run the model twice and got slightly different results. Maybe we should double-check the dataset normalization.",
            "For the client meeting next week, I’ll prepare a quick demo video and a short deck explaining the new interaction flow.",
            "Oh, that’s a good catch! I didn’t realize the API response changed after the last update — we’ll fix that in the next patch.",
            "Do we already have the final color palette approved? Because the primary blue still feels a little off-brand to me.",
            "Let’s wrap this up in the next ten minutes so everyone can have lunch — we’ll continue testing after the break.",
            "Sorry, my mic was off — yes, I agree. Let’s consolidate the notes and share them in Notion after this session.",
            "I just ran the performance benchmarks, and the new algorithm is about 25% faster than the previous version.",
            "Before we move on, can someone confirm if we’re keeping the offline transcription feature for the MVP?",
            "The user feedback from the beta test is quite positive; they especially liked the improved speech clarity.",
            "Could we try combining both approaches — maybe a hybrid model would balance accuracy and speed better?",
            "I’ll handle the deployment tomorrow morning, once the CI pipeline is stable again.",
            "Let’s not forget to anonymize all recorded data before pushing it to the test server.",
            "Thanks, everyone. I think we made great progress today — I’ll send a summary to the group chat tonight."
        ]
                
        // Simulated repeated speaker sequence
        let sequence: [String] = [
            "Speaker 1", "Speaker 2", "Speaker 3", "Speaker 4", "Speaker 5",
            "Speaker 2", "Speaker 1", "Speaker 4", "Speaker 3", "Speaker 5",
            "Speaker 1", "Speaker 2", "Speaker 4", "Speaker 3", "Speaker 1",
            "Speaker 5", "Speaker 2", "Speaker 3", "Speaker 4"
        ]

        
        for name in sequence {
            let message = dummyMessages.randomElement() ?? "Lorem ipsum dolor sit amet."
            
            // Retrieve existing or generate new profile
            let (symbol, color): (String, Color)
            if let cached = profileCache[name] {
                (symbol, color) = cached
            } else {
                let new = SpeakerData.create(name: name, message: message)
                profileCache[name] = (new.symbol, new.color)
                (symbol, color) = (new.symbol, new.color)
            }
            
            let speaker = SpeakerData(name: name, message: message, symbol: symbol, color: color)
            list.append(speaker)
        }
        
        speakers = list
    }
}


