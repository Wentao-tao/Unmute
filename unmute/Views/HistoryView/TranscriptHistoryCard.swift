//
//  TranscriptHistoryCard.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//


import SwiftUI

struct TranscriptHistoryCardEditable: View {
    @Binding var history: TranscriptHistory
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if editMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .violet4 : .violet4)
                        .padding(10)
                        .transition(.scale.combined(with: .opacity))
                }
                if isEditing {
                    TextField("Enter title", text: $history.title)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.violet8)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            withAnimation { isEditing = false }
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.isTextFieldFocused = true
                            }
                        }
                } else {
                    Text(history.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.violet8)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isEditing.toggle()
                    }
                }) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isEditing ? .green : .violet6)
                }
                .buttonStyle(.plain)
            }

            Text(history.formattedDate)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.white9)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }
}


#Preview("Transcript Card Editable") {
    @Previewable @State var sampleHistory = TranscriptHistory(
        title: "AI Research Sync",
        date: Date().addingTimeInterval(-3600)
    )

    ZStack {
        // Background wallpaper to match app
        Image("wallpaper")

        // Preview card in center
        VStack {
            TranscriptHistoryCardEditable(history: $sampleHistory)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            Spacer()
        }
    }
    .font(.system(.body, design: .rounded))
}
