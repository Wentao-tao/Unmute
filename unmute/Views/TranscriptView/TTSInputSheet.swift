//
//  TTSPopUp.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

struct TTSInputSheet: View {
    @Binding var isTTsOn: Bool
    @State private var inputText: String = ""

    var onPlay: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    RoundButton(type: .cancel) { isTTsOn.toggle() }
                        .opacity(0.6)
                        .padding(.top, 20)
                        .padding(.leading, 5)

                    Spacer()

                    LiquidGlassButton(type: .speaker, action: playTTS)
                        .padding(.top, 20)
                        .padding(.trailing, 5)
                }
                
                ZStack(alignment: .leading) {
                    if inputText.isEmpty {
                        Text("Type out your response...")
                            .foregroundColor(.violet2)
                            .padding(.horizontal, 12)
                            .font(.body)
                    }

                    TextField("", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .font(.body)
                        .frame(height: 48)
                        .foregroundColor(.violet8)
                        .onSubmit { playTTS() }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -3)
                    .ignoresSafeArea(edges: .bottom)
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.3), value: isTTsOn)
        }
    }

    private func playTTS() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        onPlay(inputText)
        withAnimation { isTTsOn = false }
    }
}


#Preview {
    @Previewable @State var isTTsOn: Bool = true

    ZStack {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .onTapGesture { withAnimation { isTTsOn = false } }
            .zIndex(3)

        TTSInputSheet(isTTsOn: $isTTsOn) { text in
            print("🎧 TTS triggered with:", text)
        }
        .zIndex(4)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
