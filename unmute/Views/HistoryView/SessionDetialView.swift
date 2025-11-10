//
//  SessionDetialView.swift
//  unmute
//
//  Created by Wentao Guo on 10/11/25.
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: TranscriptionSession
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                RoundButton(type: .back, isGlass: true) { dismiss() }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(session.sessionTitle)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.violet8)
                    
                    Text(formattedDate)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white9)
                }
                
                Spacer()
                
             
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            // Transcript Lines
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(session.lines.sorted(by: { $0.timestamp < $1.timestamp })) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.violet6)
                                
                                Text(line.speakerName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.violet8)
                            }
                            
                            Text(line.text)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.violet8.opacity(0.9))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.95, green: 0.95, blue: 1.0), location: 0.05),
                    .init(color: .white, location: 0.42)
                ],
                startPoint: UnitPoint(x: 0.5, y: -0.16),
                endPoint: UnitPoint(x: 0.5, y: 1.2)
            )
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy · HH:mm"
        return formatter.string(from: session.sessionDate)
    }
}
