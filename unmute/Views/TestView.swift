//
//  TestView.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import SwiftUI

/// Test view for the online real-time transcription feature.
/// Displays transcription results with speaker labels and provides start/stop controls.
struct TestView: View {
    @State private var vm = OnlineViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header with Status Indicator
            
            HStack {
                Text("transcriber").font(.headline)

                Spacer()

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
                                Text(
                                    "speaker "
                                        + String(vm.finalLines.speakers[index])
                                )
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
                }
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    TestView()
}
