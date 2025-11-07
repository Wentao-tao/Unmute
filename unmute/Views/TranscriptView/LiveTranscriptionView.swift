//
//  LiveTranscriptionView.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 05/11/25.
//

import SwiftUI

struct LiveTranscriptionView: View {
    @Binding var navPath: NavigationPath
    
    @State var timeElapsed: TimeInterval = 87
    @State var isRunning: Bool = true
    @State var isTTsOn: Bool = false
    @State var isStop: Bool = false
    @State var isRename: Bool = false
    @State private var navigateToSummary = false
    
    var body: some View {
        ZStack(alignment: .center) {
            
            VStack(spacing: 0) {
                TranscriptionDummyContainer(isRename: $isRename)
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
                FloatingControlBar(isRunning: $isRunning, isTTsOn: $isTTsOn, isStop: $isStop)
            }
            .zIndex(2)
            .allowsHitTesting(!isTTsOn && !isStop && !isRename)
        
            if isStop {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)

                StopConfirmation(isStop: $isStop) {
                    navPath.append("SummaryTranscript")
                }
                .zIndex(4)
            }

            
            if isRename {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)
                
                LabelSpeaker(isRename: $isRename)
                    .zIndex(4)
            }
        
            if isTTsOn {
                TTSInputSheet(isTTsOn: $isTTsOn) { text in
                    print("🎧 TTS triggered with:", text)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .zIndex(5)
                .transition(.move(edge: .bottom))
                .allowsHitTesting(true)
            }
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
        .navigationDestination(for: String.self) { value in
            if value == "SummaryTranscript" {
                SummaryTranscriptView(navPath: $navPath)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)

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
            .navigationDestination(for: String.self) { value in
                if value == "SummaryTranscript" {
                    SummaryTranscriptView(navPath: $navPath)
                }
            }
    }
}

