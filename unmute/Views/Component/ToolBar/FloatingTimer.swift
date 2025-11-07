//
//  FloatingTimer.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 05/11/25.
//


import SwiftUI

enum FloatingTimerState {
    case running
    case paused
    
    var glowColor: Color {
        switch self {
        case .running: return .violet1
        case .paused: return .red4
        }
    }
    
    var foregrounColor: Color {
        switch self {
        case .running:
            return .violet6
        case .paused:
            return .red4
        }
    }
    
    var shadow: ShadowStyle {
        switch self {
        case .running:
            return ShadowStyle(color: .violet1, radius: 22)
        case .paused:
            return ShadowStyle(color: .red4, radius: 20)
        }
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
    }
}

// MARK: - Floating Timer View
struct FloatingTimer: View {
    @Binding var timeElapsed: TimeInterval
    @Binding var isRunning: Bool
    
    var state: FloatingTimerState {
        isRunning ? .running : .paused
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1000, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            state.glowColor.opacity(0.20),
                            state.glowColor.opacity(0.20)
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
            
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text(formatTime(timeElapsed))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(state.foregrounColor)
                }
            }
        }
        .frame(width: 353, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 1000)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
        )
        .animation(.easeInOut(duration: 0.4), value: isRunning)
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var timeElapsed: TimeInterval = 87
    @Previewable @State var isRunning: Bool = true
    
    return VStack(spacing: 20) {
        FloatingTimer(timeElapsed: $timeElapsed, isRunning: $isRunning)
        
        Button(isRunning ? "Pause" : "Resume") {
            isRunning.toggle()
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(
        Image("wallpaper")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    )
}
