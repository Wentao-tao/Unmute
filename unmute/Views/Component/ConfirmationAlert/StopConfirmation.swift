//
//  StopConfirmation.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//

import SwiftUI

struct StopConfirmation: View {
    @Binding var isStop: Bool
    var onContinue: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Stop Transcription")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.violet8)
                .padding(.vertical, 10)
            
            Text("Are you sure you want to stop the transcription?")
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(.violet8)
                .padding(.bottom, 20)
            
            HStack(spacing: 20) {
                AlertButton(type: .cancel) {
                    isStop.toggle()
                }
                
                AlertButton(type: .continueButton) {
                    isStop = false
                    onContinue()  
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white2.opacity(0.5))
                .glassEffect(in: RoundedRectangle(cornerRadius: 34))
        )
        .padding(.horizontal, 40)
    }
}


//#Preview {
//    ZStack {
//        Color.black.opacity(0.2)
//            .ignoresSafeArea()
//            .transition(.opacity)
//            .zIndex(0)
//        
//        StopConfirmation(isStop: .constant(false))
//    }
//}

