import Foundation
import SwiftUI

/// Represents the current travel state of the app/session.
enum TravelState {

    // MARK: - Cases
    case idle
    case traveling
    case paused

    // MARK: - Computed (Presentation)
    /// Human‑readable label for the current travel state.
    var displayText: String {
        switch self {
        case .idle: return "Idle"
        case .traveling: return "Traveling"
        case .paused: return "Paused"
        }
    }

    /// Associated color for the current travel state.
    /// Note: This introduces a UI dependency (SwiftUI.Color); retained to preserve existing behavior.
    var color: Color {
        switch self {
        case .idle: return .gray
        case .traveling: return .green
        case .paused: return .orange
        }
    }
}
