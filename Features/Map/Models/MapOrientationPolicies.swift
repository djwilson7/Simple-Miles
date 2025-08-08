// MapOrientationPolicies.swift
// Encapsulates all per-orientation-mode rules for camera + arrow behavior.

import CoreLocation
import MapKit

// MARK: - Policy Contract
protocol MapOrientationPolicy {
    /// Determine camera heading for this mode
    func cameraHeading(predictor: TravelLocationPredictor,
                       currentHeading: CLLocationDirection) -> CLLocationDirection

    /// Compute arrow rotation for this mode
    func arrowRotation(cameraHeading: CLLocationDirection,
                       trueHeading: CLLocationDirection) -> CLLocationDirection

    /// Whether auto-follow should be enabled in this mode
    var allowsAutoFollow: Bool { get }

    /// Whether zoom changes are allowed programmatically
    var allowsZoom: Bool { get }

    /// Whether camera center can be updated programmatically
    var allowsCenterUpdate: Bool { get }
}

// MARK: - North Up
struct NorthUpPolicy: MapOrientationPolicy {
    func cameraHeading(predictor: TravelLocationPredictor,
                       currentHeading: CLLocationDirection) -> CLLocationDirection {
        0 // Always point north
    }

    func arrowRotation(cameraHeading: CLLocationDirection,
                       trueHeading: CLLocationDirection) -> CLLocationDirection {
        normalizedAngle(trueHeading - cameraHeading)
    }

    var allowsAutoFollow: Bool { true }
    var allowsZoom: Bool { true }
    var allowsCenterUpdate: Bool { true }
}

// MARK: - Heading Up
struct HeadingUpPolicy: MapOrientationPolicy {
    func cameraHeading(predictor: TravelLocationPredictor,
                       currentHeading: CLLocationDirection) -> CLLocationDirection {
        predictor.activeHeading
    }

    func arrowRotation(cameraHeading: CLLocationDirection,
                       trueHeading: CLLocationDirection) -> CLLocationDirection {
        0 // Arrow stays "forward" in heading-up mode
    }

    var allowsAutoFollow: Bool { true }
    var allowsZoom: Bool { true }
    var allowsCenterUpdate: Bool { true }
}

// MARK: - Free Roam
struct FreeRoamPolicy: MapOrientationPolicy {
    func cameraHeading(predictor: TravelLocationPredictor,
                       currentHeading: CLLocationDirection) -> CLLocationDirection {
        currentHeading // Keep whatever heading the camera already has
    }

    func arrowRotation(cameraHeading: CLLocationDirection,
                       trueHeading: CLLocationDirection) -> CLLocationDirection {
        normalizedAngle(trueHeading - cameraHeading)
    }

    var allowsAutoFollow: Bool { false }
    var allowsZoom: Bool { false }
    var allowsCenterUpdate: Bool { false }
}

// MARK: - Factory
struct MapOrientationPolicyFactory {
    static func policy(for mode: CameraOrientationMode) -> MapOrientationPolicy {
        switch mode {
        case .northUp: return NorthUpPolicy()
        case .headingUp: return HeadingUpPolicy()
        case .freeRoam: return FreeRoamPolicy()
        }
    }
}

// MARK: - Helpers
private func normalizedAngle(_ angle: CLLocationDirection) -> CLLocationDirection {
    var result = angle.truncatingRemainder(dividingBy: 360)
    if result < 0 { result += 360 }
    return result
}
