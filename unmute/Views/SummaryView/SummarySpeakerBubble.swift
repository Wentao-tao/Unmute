//
//  SummarySpeakerBubble.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

struct SummarySpeakerBubble: View {
    let symbol: String
    let name: String
    let message: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.violet8)
                
                Text(name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.violet8)
            }
            
            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.violet8.opacity(0.95))
                .padding(.top, 4)
        }
    }
}

#Preview("SummarySpeakerBubble Preview") {
    SummarySpeakerBubble(
        symbol: "person.wave.2.fill",
        name: "Speaker 1",
        message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        color: .violet6
    )
    .padding()
}
