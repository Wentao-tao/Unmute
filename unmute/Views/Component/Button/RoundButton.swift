//
//  RoundButton.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 04/11/25.
//

import SwiftUI

enum RoundButtonType {
    case cancel
    case share
    case back
    case trash
    case correct
    case selectAll
    
    var systemImage: String? {
        switch self {
        case .cancel: return "xmark"
        case .share: return "square.and.arrow.up.fill"
        case .back: return "chevron.left"
        case .trash: return "trash.fill"
        case .correct: return "checkmark"
        case .selectAll: return nil
        }
    }
    
    var title: String? {
        switch self {
        case .selectAll:
            return "Select All"
        default:
            return nil
        }
    }
}

struct RoundButton: View {
    let type: RoundButtonType
    let isGlass: Bool
    let action: () -> Void
    
    init(
        type: RoundButtonType,
        isGlass: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.type = type
        self.isGlass = isGlass
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if let icon = type.systemImage {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isGlass ? .violet4 : .white)
                } else if let text = type.title {
                    Text(text)
                        .font(.system(.footnote, design: .rounded))
                        .fontWeight(.regular)
                        .foregroundStyle(isGlass ? .violet4 : .white)
                }
            }
            .frame(
                width: type == .selectAll ? 76 : 48,
                height: 48
            )
            .background(
                ZStack {
                    if isGlass {
                        if type == .selectAll {
                            Capsule()
                                .fill(Color.white2.opacity(0.4))
                                .glassEffect(in: Capsule())
                        } else {
                            Circle()
                                .fill(Color.white2.opacity(0.4))
                                .glassEffect(in: Circle())
                        }
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
                            .clipShape(
                                type == .selectAll ? AnyShape(Capsule()) : AnyShape(Circle())
                            )

                    } else {
                        if type == .selectAll {
                            Capsule().fill(Color.violet4)
                        } else {
                            Circle().fill(Color.violet4)
                        }
                    }
                }
            )
            .clipShape(type == .selectAll ? AnyShape(Capsule()) : AnyShape(Circle()))
            .foregroundStyle(Color.violet6)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        // Plain version
        HStack(spacing: 12) {
            RoundButton(type: .cancel)
            RoundButton(type: .share)
            RoundButton(type: .back)
            RoundButton(type: .trash)
            RoundButton(type: .correct)
            RoundButton(type: .selectAll)
        }
        
        // Liquid Glass version
        HStack(spacing: 12) {
            RoundButton(type: .cancel, isGlass: true)
            RoundButton(type: .share, isGlass: true)
            RoundButton(type: .back, isGlass: true)
            RoundButton(type: .trash, isGlass: true)
            RoundButton(type: .correct, isGlass: true)
            RoundButton(type: .selectAll, isGlass: true)
        }
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

