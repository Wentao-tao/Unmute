//
//  TranscriptSummaryPrintableView.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 14/11/25.
//

import SwiftUI

struct TranscriptSummaryPrintableView: View {
    var title: String
    var date: String
    var speakerCount: Int
    var summaryText: String
    var keyPoints: [String]
    var conclusion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.violet8)
                .padding(.top, 20)

            Divider()

            HStack {
                Label(date, systemImage: "calendar")
                Spacer()
                Label("\(speakerCount) speakers", systemImage: "person.3.fill")
            }
            .font(.system(.callout, design: .rounded))
            .foregroundColor(.secondary)

            Group {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(.violet7)
                Text(summaryText)
                    .font(.body)
                    .foregroundColor(.violet8)
            }

            Group {
                Text("Key Points")
                    .font(.headline)
                    .foregroundColor(.violet7)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .bold()
                                .foregroundColor(.violet7)
                            Text(point)
                                .foregroundColor(.violet8)
                        }
                    }
                }
            }

            Group {
                Text("Conclusion")
                    .font(.headline)
                    .foregroundColor(.violet7)
                Text(conclusion)
                    .font(.body)
                    .foregroundColor(.violet8)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 34)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding()
    }
}
