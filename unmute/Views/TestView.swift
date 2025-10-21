//
//  TestView.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import SwiftUI

struct TestView: View {
    @State private var vm = OnlineViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Captions").font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {

                    ForEach(
                        Array(vm.finalLines.textLines.enumerated()),
                        id: \.offset
                    ) { index, n in
                        HStack {
                            Text(vm.finalLines.speakers[index])
                                .padding()
                            Text(n)
                                .padding()
                        }

                    }
                    Text(vm.partialLine)
                        .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            HStack {
                if vm.isRunning {
                    Button("Stop") {
                        vm.stop()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start") {
                        Task {
                            await vm.start()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

            }
        }
        .padding()
    }
}
