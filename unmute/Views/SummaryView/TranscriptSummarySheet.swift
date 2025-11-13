//
//  TranscriptSummarySheet.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

// MARK: - Transcript Summary Sheet
struct TranscriptSummarySheet: View {
    @Binding var isVisible: Bool
    var title: String
    var date: String
    var speakerCount: Int
    var summaryText: String
    var keyPoints: [String]
    var conclusion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
            
            // Centered header with equal spacing
            HStack {
                RoundButton(type: .cancel) {
                    withAnimation(.easeInOut) { isVisible = false }
                }
                .frame(width: 44, height: 44)
                
                Spacer()
                
                Text("Summary Note")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.violet8)
                
                Spacer()
                
                RoundButton(type: .share, isGlass: true) {
                    if let url = PDFExporter.exportPDF(content: {
                        TranscriptSummaryPrintableView(
                            title: title,
                            date: date,
                            speakerCount: speakerCount,
                            summaryText: summaryText,
                            keyPoints: keyPoints,
                            conclusion: conclusion
                        )
                    }) {
                        isVisible = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onShare?(url)
                        }
                    }
                }
                .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            Divider()
                .padding(.horizontal, 20)

            // Metadata
            HStack {
                Label(date, systemImage: "calendar")
                Spacer()
                Label("\(speakerCount) speakers", systemImage: "person.3.fill")
            }
            .font(.system(.callout, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            
            // Summary Section
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.violet7)
                        Text(summaryText)
                            .font(.body)
                            .foregroundColor(.violet8)
                    }
                    
                    Group {
                        Text("Key Points")
                            .font(.headline)
                            .foregroundColor(.violet7)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.violet7)
                                    Text(point)
                                        .font(.body)
                                        .foregroundColor(.violet8)
                                }
                            }
                        }
                    }
                    
                    Group {
                        Text("Conclusion")
                            .font(.headline)
                            .foregroundColor(.violet7)
                        
                        Text(conclusion)
                            .font(.body)
                            .foregroundColor(.violet8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
    }
}


#Preview {
    @Previewable @State var isVisible = true
    
    ZStack {
        Color.black.opacity(0.25).ignoresSafeArea()
        
        TranscriptSummarySheet(
            isVisible: $isVisible,
            title: "Weekly Team Meeting",
            date: "Nov 7, 2025",
            speakerCount: 5,
            summaryText: "The discussion covered project deadlines, challenges in cross-department collaboration, and plans for improving communication flow.",
            keyPoints: [
                "Speaker 1 raised concerns about time constraints.",
                "Speaker 2 proposed automation for repetitive tasks.",
                "Speaker 3 emphasized better internal feedback loops."
            ],
            conclusion: "The team agreed to test automation tools and report progress next week."
        )
    }
}
