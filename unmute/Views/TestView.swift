//
//  TestView.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import SwiftData
import SwiftUI

/// Test view for the online real-time transcription feature.
/// Displays transcription results with speaker labels and provides start/stop controls.
struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = OnlineViewModel()
    @State private var speakerName = ""
    @State private var showingNameInput = false
    @State private var selectedTime: Time_sx?
    @State private var selectedSpeakerId: Int?
    @State private var showingSessionHistory = false
    @State private var sessionTitle = ""
    @State private var showingSaveConfirmation = false
    @State private var text = ""
    @State private var tts = TTsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header with Status Indicator

            HStack {
                Text("transcriber").font(.headline)

                Spacer()

                // Session history button
                Button(action: {
                    showingSessionHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .help("view session history")

                // Clear speaker data button
                Button(action: {
                    clearSpeakerData()
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .help("clear speaker data")

                // Show running status with colored indicator
                if vm.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("running")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        Text("stop")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            VStack(spacing: 12) {
                TextField("ENTER TEXT HERE", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    
                HStack(spacing: 16) {
                    Button("SPEAK") {
                        tts.speak(text)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button("STOP") {
                        tts.stop()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.horizontal)
            }.padding()

            Divider()

            // MARK: - Transcription Display Area

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Display finalized transcription lines with speaker labels
                    if !vm.finalLines.textLines.isEmpty {
                        ForEach(
                            Array(vm.finalLines.textLines.enumerated()),
                            id: \.offset
                        ) { index, textLine in
                            HStack(alignment: .top, spacing: 12) {

                                // Speaker label badge
                                Button(
                                    "speaker "
                                        + String(vm.finalLines.name[index])
                                ) {
                                    selectedTime = vm.finalLines.times[index]
                                    selectedSpeakerId =
                                        vm.finalLines.speakers[index]
                                    showingNameInput = true
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)

                                // Transcribed text
                                Text(textLine)
                                    .font(.body)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Display partial (in-progress) transcription
                    if !vm.partialLine.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            // Placeholder indicator for partial results
                            Text("···")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)

                            // Partial text in italic style
                            Text(vm.partialLine)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }

                    // Empty state placeholder
                    if vm.finalLines.textLines.isEmpty && vm.partialLine.isEmpty
                    {
                        VStack(spacing: 16) {
                            Image(systemName: "waveform")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))

                            Text(vm.isRunning ? "listening..." : "")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxHeight: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            // MARK: - Control Buttons

            HStack(spacing: 16) {
                if vm.isRunning {
                    // Stop button with activity indicator
                    Button(action: {
                        vm.stop()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("stop")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    // Show progress indicator while running
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    // Start button
                    Button(action: {
                        Task {
                            await vm.start()
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("start")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    // Save session button (only show when not running and has content)
                    if !vm.finalLines.textLines.isEmpty {
                        Button(action: {
                            showingSaveConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("save")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .sheet(isPresented: $showingNameInput) {
            VStack(spacing: 24) {
                Text("label")
                    .font(.headline)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("for example frank", text: $speakerName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("cancel") {
                        showingNameInput = false
                        speakerName = ""
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("go") {
                        if let time = selectedTime,
                            let speakerId = selectedSpeakerId,
                            !speakerName.trimmingCharacters(in: .whitespaces)
                                .isEmpty
                        {
                            vm.enrol(
                                name: speakerName.trimmingCharacters(
                                    in: .whitespaces
                                ),
                                time: time,
                                id: speakerId
                            )
                        }
                        showingNameInput = false
                        speakerName = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        speakerName.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showingSaveConfirmation) {
            VStack(spacing: 24) {
                Text("Save Session")
                    .font(.headline)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Title (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("e.g., Team Meeting", text: $sessionTitle)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    Button("cancel") {
                        showingSaveConfirmation = false
                        sessionTitle = ""
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("save") {
                        Task { @MainActor in
                            _ = await vm.saveSession(
                                to: modelContext,
                                title: sessionTitle
                            )
                            showingSaveConfirmation = false
                            sessionTitle = ""
                            // Optionally clear the current session after saving
                            vm.finalLines.clear()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .presentationDetents([.height(220)])
        }
        .sheet(isPresented: $showingSessionHistory) {
            SessionHistoryView()
        }
    }

    private func clearSpeakerData() {
        Task { @MainActor in
            VoiceService.shared.registry?.clear()
        }
    }
}

/// View to display saved transcription sessions
struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TranscriptionSession.sessionDate, order: .reverse) private
        var sessions: [TranscriptionSession]
    @State private var selectedSession: TranscriptionSession?

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    Button(action: {
                        selectedSession = session
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.sessionTitle)
                                .font(.headline)
                            Text(session.sessionDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.lines.count) lines")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .navigationTitle("Session History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            modelContext.delete(session)
        }
        do {
            try modelContext.save()
        } catch {
            print("❌ Session History: Failed to delete sessions: \(error.localizedDescription)")
        }
    }
}

/// View to display details of a single session
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: TranscriptionSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(session.lines) { line in
                        HStack(alignment: .top, spacing: 12) {
                            Text("speaker \(line.speakerName)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)

                            Text(line.text)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle(session.sessionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TestView()
}
