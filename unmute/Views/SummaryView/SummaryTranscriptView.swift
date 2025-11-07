//
//  SummaryTranscriptView.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

struct SummaryTranscriptView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navPath: NavigationPath
    
    @State private var transcriptTitle: String = "Transcript Title"
    @State private var speakers: [SpeakerData] = []
    @State private var isSummarize: Bool = false
    var onSummarize: (() -> Void)? = nil

    var body: some View {
    
        VStack(spacing: 0) {
                TextField("", text: $transcriptTitle)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.violet8)
                    .multilineTextAlignment(.center)

            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(speakers) { speaker in
                        SummarySpeakerBubble(
                            symbol: speaker.symbol,
                            name: speaker.name,
                            message: speaker.message,
                            color: speaker.color
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 34)
                    .fill(Color.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            Spacer()
            
            HStack(spacing: 20) {
                LiquidGlassButton(type: .summarize) {
                    isSummarize.toggle()
                }
                
                RoundButton(type: .cancel) {
                    navPath.removeLast(navPath.count)
                }            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: -1)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.95, green: 0.95, blue: 1.0), location: 0.05),
                    .init(color: .white, location: 0.42)
                ],
                startPoint: UnitPoint(x: 0.5, y: -0.16),
                endPoint: UnitPoint(x: 0.5, y: 1.2)
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)

        .background(
            Image("wallpaper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
        .onAppear {
            generateSpeakers()
        }
        .sheet(isPresented: $isSummarize) {
            TranscriptSummarySheet(
                isVisible: $isSummarize,
                title: transcriptTitle,
                date: "Nov 7, 2025",
                speakerCount: speakers.count,
                summaryText: """
                The discussion focused on improving workflow efficiency, resolving communication issues, and aligning team goals for the next sprint.
                """,
                keyPoints: [
                    "Speaker 1 emphasized better sprint planning.",
                    "Speaker 2 proposed adopting automation tools.",
                    "Speaker 3 highlighted collaboration improvements."
                ],
                conclusion: "The team decided to adopt a shared planning tool and review its effectiveness next week."
            )
            .presentationCornerRadius(34)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled(false)
        }

    }
    
    // MARK: - Same Dummy Generator as LiveTranscriptionView
    private func generateSpeakers() {
        var profileCache: [String: (String, Color)] = [:]
        var list: [SpeakerData] = []
        
        let dummyMessages: [String] = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Incididunt ut labore et dolore magna aliqua.",
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
            "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
            "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        ]
        
        let sequence: [String] = [
            "Speaker 1", "Speaker 2", "Speaker 3", "Speaker 4", "Speaker 5",
            "Speaker 3", "Speaker 1", "Speaker 2", "Speaker 5", "Speaker 4"
        ]
        
        for name in sequence {
            let message = dummyMessages.randomElement() ?? ""
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

#Preview {
    @Previewable @State var navPath = NavigationPath()

    SummaryTranscriptView(navPath: $navPath, onSummarize: {
        print("🧠 Summarizing transcript...")
    })
        .font(.system(.body, design: .rounded))
        .background(
            Image("wallpaper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
}
