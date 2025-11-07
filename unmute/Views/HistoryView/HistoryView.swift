//
//  HistoryView.swift
//  OgmoApp
//
//  Created by Babe on 07/11/25.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var histories: [TranscriptHistory] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RoundButton(type: .back, isGlass: true) { dismiss() }

                Spacer()

                Text("Transcript History")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.violet5)

                Spacer()

                RoundButton(type: .trash) {
                    deleteAllHistories()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.violet4)

                TextField("Find your transcripts...", text: $searchText)
                    .foregroundColor(.violet4)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 1000)
                    .fill(Color.violet0)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // MARK: - Transcript History List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(filteredHistories) { history in
                        TranscriptHistoryCardEditable(history: binding(for: history))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }

            Spacer()
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
        .onAppear(perform: loadDummyHistory)
    }

    // MARK: - Computed Filtered Data
    private var filteredHistories: [TranscriptHistory] {
        if searchText.isEmpty {
            return histories
        } else {
            return histories.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Helper to get a binding to an element in histories array
    private func binding(for history: TranscriptHistory) -> Binding<TranscriptHistory> {
        guard let index = histories.firstIndex(where: { $0.id == history.id }) else {
            fatalError("History not found")
        }
        return $histories[index]
    }

    // MARK: - Functions
    private func loadDummyHistory() {
        histories = [
            TranscriptHistory(title: "Team Meeting Recap", date: Date().addingTimeInterval(-3600)),
            TranscriptHistory(title: "Interview with Client", date: Date().addingTimeInterval(-86400)),
            TranscriptHistory(title: "Design Sprint Discussion", date: Date().addingTimeInterval(-172800)),
            TranscriptHistory(title: "AI Research Sync", date: Date().addingTimeInterval(-259200))
        ]
    }

    private func deleteAllHistories() {
        withAnimation {
            histories.removeAll()
        }
    }
}

#Preview {
    HistoryView()
        .font(.system(.body, design: .rounded))
        .background(
            Image("wallpaper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
}
