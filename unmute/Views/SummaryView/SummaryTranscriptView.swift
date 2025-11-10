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
    
    // Transcription data from live session
    let transcriptionLines: [String]
    let speakerNames: [String]
    let speakerIds: [Int]
    
    @State private var transcriptTitle: String = "Transcript Title"
    @State private var isEditingTitle = false
    @State private var isSummarize: Bool = false
    @FocusState private var isTitleFocused: Bool
    var onSummarize: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                RoundButton(type: .back, isGlass: true) { 
                    navPath.removeLast(navPath.count)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    // Editable title
                    if isEditingTitle {
                        TextField("Enter title", text: $transcriptTitle)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.violet8)
                            .multilineTextAlignment(.center)
                            .focused($isTitleFocused)
                            .onSubmit {
                                isEditingTitle = false
                            }
                    } else {
                        Text(transcriptTitle)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.violet8)
                            .onTapGesture {
                                isEditingTitle = true
                                isTitleFocused = true
                            }
                    }
                    
                    Text(formattedDate)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white9)
                }
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            // Transcript Lines
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(transcriptionLines.enumerated()), id: \.offset) { index, line in
                        let name = speakerNames.indices.contains(index) ? speakerNames[index] : "Unknown"
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.violet6)
                                
                                Text(name)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.violet8)
                            }
                            
                            Text(line)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.violet8.opacity(0.9))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            
            // Bottom button bar
            HStack(spacing: 20) {
                LiquidGlassButton(type: .summarize) {
                    isSummarize.toggle()
                }
                
                RoundButton(type: .cancel) {
                    navPath.removeLast(navPath.count)
                }
            }
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
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Auto-generate title with current date and time
            if transcriptTitle == "Transcript Title" {
                transcriptTitle = "Meeting \(Date().formatted(date: .abbreviated, time: .shortened))"
            }
        }
        .sheet(isPresented: $isSummarize) {
            TranscriptSummarySheet(
                isVisible: $isSummarize,
                title: transcriptTitle,
                date: Date().formatted(date: .abbreviated, time: .omitted),
                speakerCount: Set(speakerNames).count,
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
    
    private var formattedDate: String {
        Date().formatted(date: .abbreviated, time: .shortened)
    }
}

#Preview {
    @Previewable @State var navPath = NavigationPath()

    SummaryTranscriptView(
        navPath: $navPath,
        transcriptionLines: [
            "Hello, how are you doing today?",
            "I'm doing great, thanks for asking!",
            "Let's discuss the project timeline.",
            "Sure, I think we should focus on the MVP first.",
            "That sounds like a good plan."
        ],
        speakerNames: ["Alice", "Bob", "Alice", "Bob", "Alice"],
        speakerIds: [1, 2, 1, 2, 1],
        onSummarize: {
            print("🧠 Summarizing transcript...")
        }
    )
    .font(.system(.body, design: .rounded))
}
