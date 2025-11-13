//
//  HomeView.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 05/11/25.
//
import SwiftUI

struct HomeView: View {
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack {
                HStack{
                    Spacer()
                    FloatingHeaderBar(
                        onHistory: { navPath.append(NavigationDestination.history) },
                        onSettings: { navPath.append(NavigationDestination.settings) }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom)
                }
                
                
                Text("Ready to start")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.violet7)
                    .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .center))
                    .padding(.top, 8)
                    .padding(.horizontal)
                Text("transcribing?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.violet5)
                    .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .center))
                    .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(value: NavigationDestination.liveTranscription) {
                    VStack{
                        Image(systemName: "microphone.fill")
                            .resizable()
                            .frame(width: 64, height: 81)
                            .foregroundStyle(.yellow3)
                            .padding(50)
                            .background(Color(.violet7))
                            .clipShape(Circle())
                        Text("Tap to start")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .padding(.top, 5)
                            .foregroundStyle(.violet1)

                    }
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

            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .liveTranscription:
                    LiveTranscriptionView(navPath: $navPath)
                case .summaryTranscript(let lines, let names, let ids):
                    SummaryTranscriptView(
                        navPath: $navPath,
                        transcriptionLines: lines,
                        speakerNames: names,
                        speakerIds: ids
                    )
                case .history:
                    HistoryView()
                case .settings:
                    SettingView()
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
    
        }


    }
}

#Preview {
    HomeView()
}
