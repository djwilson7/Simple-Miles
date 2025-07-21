// MotionSensitivityLevel.swift

import Foundation
import CoreLocation

enum MotionSensitivityLevel: String, CaseIterable, Identifiable, CustomStringConvertible {
    case low
    case medium
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var speedThreshold: CLLocationSpeed {
        switch self {
        case .low: 5.0
        case .medium: 2.5
        case .high: 1.0
        }
    }

    var accelerationThreshold: Double {
        switch self {
        case .low: 2.5
        case .medium: 1.5
        case .high: 0.75
        }
    }

    var description: String {
        switch self {
        case .low: "Ignore small movements."
        case .medium: "Balanced for most drivers."
        case .high: "Sensitive to small movements."
        }
    }

}
