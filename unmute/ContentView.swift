//
//  ContentView.swift
//  unmute
//
//  Created by Wentao Guo on 02/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                TestView()
            }
            .padding()
            .navigationTitle("Speech Recognition")
        }
    }
}

#Preview {
    ContentView()
}
