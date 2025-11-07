//
//  FloatingHeaderBar.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

struct FloatingHeaderBar: View {
    var onHistory: () -> Void
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1000, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.violet1.opacity(0.15), .violet1.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 12)
                .shadow(color: .violet1.opacity(0.5), radius: 18, x: 0, y: 0)

            RoundedRectangle(cornerRadius: 1000, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 1000)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

            HStack(spacing: 10) {
                Button(action: onHistory){
                    Image(systemName: "hourglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.violet7)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.violet7)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 99, height: 48)
        .padding(.top, 10)
        .animation(.easeInOut(duration: 0.3), value: true)
    }
}

#Preview {
    ZStack {
        Image("wallpaper")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()

        VStack {
            FloatingHeaderBar(
                onHistory: { print("🕰️ History tapped") },
                onSettings: { print("⚙️ Settings tapped") }
            )
            Spacer()
        }
    }
}
