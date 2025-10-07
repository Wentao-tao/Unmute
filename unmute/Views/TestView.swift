//
//  TestView.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import SwiftUI

struct TestView: View {
    @StateObject private var vm = TestViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text(vm.state)
                .font(.headline)

            HStack {
                Button("Record 5s") { vm.record(seconds: 5) }
                Button("Play") { vm.play() }
                Button("Stop") { vm.stopPlayback() }
            }

            if let url = vm.lastFileURL {
                Text("Saved: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
