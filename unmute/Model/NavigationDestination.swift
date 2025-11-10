//
//  NavigationDestination.swift
//  unmute
//
//  Created by Wentao
//

import Foundation

/// Defines all possible navigation destinations in the app
enum NavigationDestination: Hashable {
    case liveTranscription
    case summaryTranscript(lines: [String], names: [String], ids: [Int])
    case history
    case settings
}

