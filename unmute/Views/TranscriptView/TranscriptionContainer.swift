//
//  TranscriptionContainer.swift
//  unmute
//
//  Created by Wentao Guo on 07/11/25.
//

import SwiftUI

struct TranscriptionContainer: View {
    @Binding var isRename: Bool
    var viewModel: OnlineViewModel

    var onRename: (Int) -> Void

    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(
                            viewModel.finalLines.textLines.indices,
                            id: \.self
                        ) { index in
                            let line = viewModel.finalLines.textLines[index]
                            let name = viewModel.finalLines.name[index]
                            let speakerid = viewModel.finalLines.speakers[index]
                            let profile = SpeakerData.create(name: name, message: "")

                            SpeakerBubble(
                                symbol: profile.symbol,
                                name: name,
                                message: line,
                                color: profile.color,
                                speakerID: speakerid,
                                isRename: $isRename,
                                onRename: onRename

                            )
                            .id(index)
                        }
                        if !viewModel.partialLine.isEmpty {
                            PartialSpeakerBubble(
                                message: viewModel.partialLine
                            )
                            .id("partial")
                        }

                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 40)
                    .onChange(of: viewModel.finalLines.textLines.count) {
                        _,
                        _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.partialLine) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        // Auto-scroll to bottom when new message arrives
        if !viewModel.partialLine.isEmpty {
            withAnimation {
                proxy.scrollTo("partial", anchor: .bottom)
            }
        } else if let lastIndex = viewModel.finalLines.textLines.indices.last {
            withAnimation {
                proxy.scrollTo(lastIndex, anchor: .bottom)
            }
        }
    }
}

/// Partial (in-progress) speaker bubble component
struct PartialSpeakerBubble: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {

                HStack(spacing: 3) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.violet6.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .scaleEffect(animationScale)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animationScale
                            )
                    }
                }

                Text("...")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.violet6.opacity(0.6))
            }

            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.violet8.opacity(0.6))
                .italic()
        }
        .onAppear {
            withAnimation {
                animationScale = 1.3
            }
        }
    }

    @State private var animationScale: CGFloat = 1.0
}
