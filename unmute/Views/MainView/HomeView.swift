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
                        onHistory: { navPath.append("History") },
                        onSettings: { navPath.append("Settings") }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom)
                }
                
                

                Text("Ready to start transcribing, [name]?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                Spacer()
                
                NavigationLink(value: "LiveTranscription") {
                    VStack{
                        Image(systemName: "microphone.circle.fill")
                            .resizable()
                            .frame(width: 144, height: 144)
                            .foregroundStyle(.black)
                            .padding(.bottom, 20)
                        Text("Tap to start")
                            .font(.callout)
                            .foregroundStyle(.white7)

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

            .navigationDestination(for: String.self) { value in
                switch value {
                case "LiveTranscription":
                    LiveTranscriptionView(navPath: $navPath)
                case "SummaryTranscript":
                    SummaryTranscriptView(navPath: $navPath)
                case "History":
                    HistoryView()
                case "Settings":
                    SettingView()
                default:
                    EmptyView()
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
