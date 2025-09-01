import Foundation
import SwiftUI

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
