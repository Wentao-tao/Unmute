//
//  LabelSpeaker.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

struct LabelSpeaker: View {
    @Binding var isRename: Bool
    @State private var inputText: String = "" // will be move on the model view
    var body: some View {
        VStack(alignment: .leading) {
            Text("Label Speaker")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.violet8)
                .padding(.vertical, 10)
            
            Text("Label your speaker to keep it in the transcript")
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(.violet8)
            
            VStack(alignment: .leading) {
                TextField("Enter text...", text: $inputText)
                    .font(.system(.body, design: .rounded))
                    .padding(16)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 1000, style: .continuous)
                            .fill(Color.violet0)
                    )
                    .foregroundColor(.violet8)
            }
            .padding(.vertical, 15)
            
            HStack(spacing: 20) {
                AlertButton(type: .cancel,action: { isRename.toggle() })
                AlertButton(type: .continueButton,action: { isRename.toggle() })
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white2.opacity(0.5))
                .glassEffect(in: RoundedRectangle(cornerRadius: 34))
                
        )
        .padding(.horizontal,40)
    }
}

//#Preview {
//    LabelSpeaker()
//        .background(.violet0)
//}
