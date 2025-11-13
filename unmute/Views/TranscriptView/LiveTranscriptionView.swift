//
//  LiveTranscriptionView.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 05/11/25.
//

import SwiftData
import SwiftUI

struct LiveTranscriptionView: View {
    @Binding var navPath: NavigationPath
    @Environment(\.modelContext) private var modelContext

    @State private var transcriptionVM = OnlineViewModel()
    @State private var timer: Timer?

    @State private var selectedID = -1

    @State var timeElapsed: TimeInterval = 0
    @State var isRunning: Bool = false
    @State var isTTsOn: Bool = false
    @State var isStop: Bool = false
    @State var isRename: Bool = false

    var body: some View {
        ZStack(alignment: .center) {

            VStack(spacing: 0) {
                TranscriptionContainer(
                    isRename: $isRename,
                    viewModel: transcriptionVM
                ) {
                    id in self.selectedID = id
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 70)
                }
            }
            .padding(.horizontal, 15)
            .zIndex(1)
            .allowsHitTesting(!isStop && !isTTsOn && !isRename)
            VStack {
                FloatingTimer(timeElapsed: $timeElapsed, isRunning: $isRunning)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.4), value: isRunning)

                Spacer()
                FloatingControlBar(
                    isRunning: $isRunning,
                    isTTsOn: $isTTsOn,
                    isStop: $isStop
                )
            }
            .zIndex(2)
            .allowsHitTesting(!isTTsOn && !isStop && !isRename)

            if isStop {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)

                StopConfirmation(isStop: $isStop) {
                    Task {
                        await stopTranscription()
                    }
                    // Navigate to summary with real transcription data
                    navPath.append(NavigationDestination.summaryTranscript(
                        lines: transcriptionVM.finalLines.textLines,
                        names: transcriptionVM.finalLines.name,
                        ids: transcriptionVM.finalLines.speakers
                    ))
                }
                .zIndex(4)
            }

            if isRename {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)

                LabelSpeaker(isRename: $isRename) { name in
                    Task {
                        transcriptionVM.enrol(name: name, id: selectedID)
                    }

                }
                .zIndex(4)
            }

            if isTTsOn {
                TTSInputSheet(isTTsOn: $isTTsOn)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .zIndex(5)
                    .transition(.move(edge: .bottom))
                    .allowsHitTesting(true)
            }
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
        .navigationBarBackButtonHidden(true)
        .onChange(of: isRunning) { oldValue, newValue in
            if newValue && !oldValue {
                Task {
                    if transcriptionVM.finalLines.textLines.isEmpty {
                        await startTranscription()
                    } else {
                        await transcriptionVM.resume()
                    }
                }
            } else if !newValue && oldValue {

                transcriptionVM.pause()

            }

        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onAppear {
            if !transcriptionVM.isRunning {
                Task {
                    await startTranscription()
                    isRunning = true
                }
            }
        }

    }

    private func startTranscription() async {
        await transcriptionVM.start()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            _ in
            if transcriptionVM.isRunning {
                timeElapsed += 1
            }
        }
    }

    private func stopTranscription() async {
        isRunning = false
        transcriptionVM.stop()
        timer?.invalidate()
        timer = nil

        _ = await transcriptionVM.finalLines.saveSession(
            to: modelContext,
            title:
                "Meeting \(Date().formatted(date: .abbreviated, time: .shortened))"
        )
    }
}

#Preview {
    @Previewable @State var navPath = NavigationPath()

    NavigationStack(path: $navPath) {
        LiveTranscriptionView(navPath: $navPath)
            .font(.system(.body, design: .rounded))
            .background(
                Image("wallpaper")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            // Navigation destination for preview flow
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .summaryTranscript(let lines, let names, let ids):
                    SummaryTranscriptView(
                        navPath: $navPath,
                        transcriptionLines: lines,
                        speakerNames: names,
                        speakerIds: ids
                    )
                default:
                    EmptyView()
                }
            }
    }
}
