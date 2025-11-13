//
//  LiquidGlassButton.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 04/11/25.
//

import SwiftUI

enum LiquidGlassButtonType {
    case speaker
    case summarize
    case checkSummary
    case logOut
    
    var title: String? {
        switch self {
        case .speaker:
            return nil
        case .summarize:
            return "Summarize"
        case .checkSummary:
            return "Check Summary"
        case .logOut:
            return "Log Out"
        }
    }

    var frameSize: CGSize {
        switch self {
        case .speaker:
            return CGSize(width: 140, height: 54)
        case .summarize, .checkSummary:
            return CGSize(width: 280, height: 54)
        case .logOut:
            return CGSize(width: 353, height: 48)
        }
    }
    
    var systemImage: String? {
        switch self {
        case .speaker:
            return "speaker.wave.2.fill"
        default:
            return nil
        }
    }
    
    var foreground: Color {
        switch self {
        case .logOut:
            return .red6
        case .checkSummary, .speaker, .summarize:
            return .yellow1
        }
    }
    
    var background: Color {
        switch self {
        case .logOut:
            return .white2
        case .checkSummary, .speaker, .summarize:
            return .violet7
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .logOut:
            return .medium   
        case .checkSummary, .speaker, .summarize:
            return .semibold
        }
    }
}

struct LiquidGlassButton: View {
    let type: LiquidGlassButtonType
    let action: () -> Void
    
    init(type: LiquidGlassButtonType, action: @escaping () -> Void = {}) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = type.systemImage {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                }
                if let title = type.title {
                    Text(title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(type.fontWeight) 
                }
            }
            .frame(width: type.frameSize.width, height: type.frameSize.height)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 1000, style: .continuous)
                        .fill(type.background)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 1000))
                    
                    if type == .logOut {
                        // Blackish gradient overlay for depth
                        RoundedRectangle(cornerRadius: 1000, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0),
                                        Color.black.opacity(0.04)
                                    ]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    }
                }
            )
            .foregroundStyle(type.foreground)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            LiquidGlassButton(type: .speaker)
        }
        LiquidGlassButton(type: .summarize)
        LiquidGlassButton(type: .checkSummary)
        LiquidGlassButton(type: .logOut)
    }
    .padding()
    .font(.system(.body, design: .rounded))
    .background(
        Image("wallpaper")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    )
}
