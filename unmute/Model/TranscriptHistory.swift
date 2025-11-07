//
//  TranscriptHistory.swift
//  OgmoApp
//
//  Created by Muhammad Dwiva Arya Erlangga on 06/11/25.
//
import SwiftUI

struct TranscriptHistory: Identifiable {
    let id = UUID()
    var title: String
    var date: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy · HH:mm"
        return formatter.string(from: date)
    }
}
