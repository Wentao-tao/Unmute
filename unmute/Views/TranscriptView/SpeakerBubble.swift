//
//  SpeakerBubble.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

// MARK: - Reusable Speaker Bubble Component
struct SpeakerBubble: View {
    let symbol: String
    let name: String
    let message: String
    let color: Color
    let speakerID: Int
    @Binding var isRename: Bool
    
    var onRename: (Int) -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                
                Text(name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                
                Button(action: {
                    isRename.toggle()
                    onRename(speakerID)
                }) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading,4)
            }
            
            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.violet8.opacity(0.95))
        }
    }
}


#Preview("SpeakerBubble Preview") {
    @Previewable @State var isRename: Bool = false
    SpeakerBubble(
        symbol: "person.fill",
        name: "Alice",
        message: "This is a sample message shown inside the speaker bubble to preview the layout and styling.",
        color: .violet8,
        speakerID: 1,
        isRename: $isRename, onRename: {id in }
    )
    .padding()
}
