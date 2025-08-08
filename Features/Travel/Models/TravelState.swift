//
//  TravelState.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/8/25.
//
import Foundation
import SwiftUI

// MARK: - State Enum
enum TravelState {
    case idle
    case traveling
    case paused
    
    var displayText: String {
        switch self {
        case .idle: return "Idle"
        case .traveling: return "Traveling"
        case .paused: return "Paused"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .gray
        case .traveling: return .green
        case .paused: return .orange
        }
    }
}
