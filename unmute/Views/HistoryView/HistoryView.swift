//
//  HistoryView.swift
//  OgmoApp
//
//  Created by Babe on 07/11/25.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TranscriptionSession.sessionDate, order: .reverse) private
        var sessions: [TranscriptionSession]
    @State private var searchText: String = ""
    @State private var histories: [TranscriptHistory] = []
    @State private var editMode: Bool = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showDeleteConfirmation: Bool = false
    // Track selected session for navigation
    @State private var selectedSession: TranscriptionSession?

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

                RoundButton(type: editMode ? .correct : .trash) {
                    withAnimation(.spring()) {
                        if editMode {
                            histories.removeAll { selectedIDs.contains($0.id) }
                            selectedIDs.removeAll()
                            editMode = false
                        } else {
                            // Enter edit mode
                            editMode = true
                        }
                    }
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
                    ForEach(filteredSessions) { session in
                        SessionHistoryCard(session: session) {
                            // Navigate to detail view when card is tapped (not in editing mode)
                            selectedSession = session
                        }
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
                    .init(
                        color: Color(red: 0.95, green: 0.95, blue: 1.0),
                        location: 0.05
                    ),
                    .init(color: .white, location: 0.42),
                ],
                startPoint: UnitPoint(x: 0.5, y: -0.16),
                endPoint: UnitPoint(x: 0.5, y: 1.2)
            )
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
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

    private var filteredSessions: [TranscriptionSession] {
        if searchText.isEmpty {
            return sessions
        } else {
            return sessions.filter {
                $0.sessionTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Functions

    private func deleteAllHistories() {
        withAnimation {
            for session in sessions {
                modelContext.delete(session)
            }
            try? modelContext.save()
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
