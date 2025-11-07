//
//  Untitled.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 04/11/25.
//

import SwiftUI

enum AlertButtonType {
    case export
    case continueButton
    case logout
    case delete
    case cancel
    
    var title: String {
        switch self {
        case .export: return "Export"
        case .continueButton: return "Continue"
        case .logout: return "Log out"
        case .delete: return "Delete"
        case .cancel: return "Cancel"
        }
    }
    
    var colorBg: Color {
        switch self {
        case .export, .continueButton:
            return .violet7
        case .delete, .logout, .cancel:
            return .white5
        }
    }

    var colorText: Color {
        switch self {
        case .export, .continueButton:
            return .yellow1
        case .cancel, .logout:
            return .violet5
        case .delete:
            return .red6
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .export, .continueButton:
            return .semibold   
        case .delete, .logout, .cancel:
            return .medium
        }
    }
}

struct AlertButton: View {
    let type: AlertButtonType
    let action: () -> Void
    
    init(type: AlertButtonType, action: @escaping () -> Void = {}) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(type.title)
                .font(.system(.body, design: .rounded))
                .fontWeight(type.fontWeight)
                .padding()
                .frame(width: 120, height: 48)
                .background(type.colorBg)
                .foregroundColor(type.colorText)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
//        .padding(.horizontal)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        AlertButton(type: .export)
        AlertButton(type: .cancel)
        AlertButton(type: .delete)
        AlertButton(type: .continueButton)
        AlertButton(type: .logout)
    }
    .font(.system(.body, design: .rounded))
    .padding()
}
