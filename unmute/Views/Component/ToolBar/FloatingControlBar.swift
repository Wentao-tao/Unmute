//
//  FloatingControlBar.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

enum ControlBarState {
    case running
    case paused
    
    var glowColor: Color {
        switch self {
        case .running: return .violet1
        case .paused: return .red4
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .running: return .violet6
        case .paused: return .red4
        }
    }
    
    var stopColor: Color {
        switch self {
        case .running: return .violet6
        case .paused: return .red4
        }
    }
    
    var ttsColor: Color {
        switch self {
        case .running: return .violet6
        case .paused: return .red4
        }
    }
    var shadow: FloatingTimerState.ShadowStyle {
        switch self {
        case .running:
            return .init(color: .violet1.opacity(0.5), radius: 22)
        case .paused:
            return .init(color: .red4.opacity(0.5), radius: 20)
        }
    }
}

struct FloatingControlBar: View {
    @Binding var isRunning: Bool
    @Binding var isTTsOn: Bool
    @Binding var isStop: Bool
    
    private var state: ControlBarState {
        isRunning ? .running : .paused
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1000, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            state.glowColor.opacity(0.18),
                            state.glowColor.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 14)
                .shadow(color: state.shadow.color, radius: state.shadow.radius, x: 0, y: 0)
            
            RoundedRectangle(cornerRadius: 1000, style: .continuous)
                .fill(Color.white)
                .glassEffect(in: RoundedRectangle(cornerRadius: 1000))
                .overlay(
                    RoundedRectangle(cornerRadius: 1000)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
            
            HStack(spacing: 65) {
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isRunning.toggle()
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .id(isRunning)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(state.foregroundColor)
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTTsOn.toggle()
                    }
                } label: {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(state.ttsColor)
                }
                .buttonStyle(.plain)
                
                Button {
                    isStop.toggle()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(state.stopColor)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 280, height: 49)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var isRunning = true
    @Previewable @State var isTTsOn = false
    @Previewable @State var isStop = false
    return VStack(spacing: 20) {
        FloatingControlBar(
            isRunning: $isRunning,
            isTTsOn: $isTTsOn,
            isStop: $isStop
        )
    }
    .padding()
    .background(
        Image("wallpaper")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    )
}
