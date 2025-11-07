//
//  SecondaryButton.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 04/11/25.
//

import SwiftUI

enum SecondaryButtonType {
    case cancel
    case done
    case export
    case `continue`
    case letsBegin
    case welcome
    
    var title: String {
        switch self {
        case .cancel: return "Cancel"
        case .done: return "Done"
        case .export: return "Export"
        case .continue: return "Continue"
        case .letsBegin: return "Let's Begin!"
        case .welcome: return "Welcome"
        }
    }
    
    var colorBg: Color {
        switch self {
        case .cancel, .done:
            return .white4
        case .export, .continue, .letsBegin, .welcome:
            return .violet7
        }
    }
    
    var colorText: Color {
        switch self {
        case .cancel, .done:
            return .violet5
        case .export, .continue, .letsBegin, .welcome:
            return .yellow1
        }
    }
    
    var frameWidth: CGFloat {
        switch self {
        case .cancel, .done, .export:
            return 260
        case .continue, .letsBegin, .welcome:
            return 170
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .cancel, .done:
            return .medium    
        case .export, .continue, .letsBegin, .welcome:
            return .semibold
        }
    }
}

struct SecondaryButton: View {
    let type: SecondaryButtonType
    let action: () -> Void
    
    init(type: SecondaryButtonType, action: @escaping () -> Void = {}) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(type.title)
                .font(.system(.body, design: .rounded))
                .fontWeight(type.fontWeight)
                .frame(width: type.frameWidth, height: 48)
                .background(type.colorBg)
                .foregroundColor(type.colorText)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        SecondaryButton(type: .cancel)
        SecondaryButton(type: .done)
        SecondaryButton(type: .export)
        SecondaryButton(type: .continue)
        SecondaryButton(type: .letsBegin)
        SecondaryButton(type: .welcome)
    }
    .font(.system(.body, design: .rounded))
    .padding()
}
