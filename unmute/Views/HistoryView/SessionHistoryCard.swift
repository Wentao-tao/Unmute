//
//  SessionHistoryCard.swift
//  unmute
//
//  Created by Wentao Guo on 10/11/25.
//

import SwiftUI
import SwiftData

struct SessionHistoryCard: View {
    @Environment(\.modelContext) private var modelContext
    let session: TranscriptionSession
    var onTap: () -> Void
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if isEditing {
                    TextField("Enter title", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.violet8)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            saveTitle()
                        }
                        .onAppear {
                            editedTitle = session.sessionTitle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.isTextFieldFocused = true
                            }
                        }
                } else {
                    Text(session.sessionTitle)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.violet8)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isEditing {
                            saveTitle()
                        } else {
                            isEditing = true
                        }
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.line")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isEditing ? .green : .violet6)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(formattedDate)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white9)
                
                Spacer()
                
                Text("\(session.lines.count) lines")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white9)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy · HH:mm"
        return formatter.string(from: session.sessionDate)
    }
    
    private func saveTitle() {
        session.sessionTitle = editedTitle
        try? modelContext.save()
        withAnimation {
            isEditing = false
        }
    }
}
