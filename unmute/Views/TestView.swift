//
//  TestView.swift
//  unmute
//
//  Created by Wentao Guo on 06/10/25.
//

import SwiftUI

struct TestView: View {
    @State private var vm = TestViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Captions").font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        vm.renderedTranscript
                    )
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                   
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            HStack {
                if vm.isRunning {
                    Button("Stop") {
                        Task {
                            do { try await vm.stop() } catch {
                                print(error)
                            }

                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start") {
                        Task {
                            do { try await vm.start() } catch {
                                print(error)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

            }
        }
        .padding()
    }
}
