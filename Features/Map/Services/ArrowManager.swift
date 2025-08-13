import Foundation
import Combine
import CoreLocation
import MapKit

/// Manages the arrow rotation based on camera heading, travel heading, map heading, and device orientation mode.
/// Uses a unified CombineLatest stream to respond to all relevant heading and mode updates.
final class ArrowHeadingManager: ObservableObject {

    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = ArrowHeadingManager()

    // MARK: - Dependencies

    private let cameraManager = CameraManager.shared
    private let travelLocationPredictor = TravelLocationPredictor.shared
    private let travelStateManager = TravelStateManager.shared

    // MARK: - Published State

    /// The computed arrow rotation to be displayed (in degrees)
    @Published var desiredArrowRotation: CLLocationDirection = 0

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()
    private var lastRotation: CLLocationDirection = 0
    private var travelState: TravelState = .idle

    // MARK: - Initialization

    /// Private initializer to enforce singleton usage
    private init() {
        bind()
    }

    private func bind() {
        travelStateManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: \.travelState, on: self)
            .store(in: &cancellables)

        Publishers
            .CombineLatest4(
                cameraManager.$currentHeading,
                travelLocationPredictor.$activeHeading,
                cameraManager.$mapHeading,
                cameraManager.$orientationMode
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cameraHeading, activeHeading, mapHeading, orientationMode in
                guard let self = self else { return }
                self.updateArrowRotation(
                    cameraHeading: cameraHeading,
                    trueHeading: activeHeading,
                    mapHeading: mapHeading,
                    orientation: orientationMode
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Arrow Update Logic

    /// Updates the arrow rotation based on current camera heading, active heading, map heading, and camera orientation mode.
    /// - Parameters:
    ///   - cameraHeading: The current camera heading
    ///   - trueHeading: The active true heading used for navigation
    ///   - mapHeading: The current map heading
    ///   - orientation: The current camera orientation mode
    private func updateArrowRotation(
        cameraHeading: CLLocationDirection,
        trueHeading: CLLocationDirection,
        mapHeading: CLLocationDirection,
        orientation: CameraOrientationMode
    ) {
        let targetAngle: CLLocationDirection
        
        switch orientation {
        case .headingUp:
            targetAngle = setArrowModeHeadsUp()
        case .northUp:
            targetAngle = setArrowModeNorthUp(trueHeading: trueHeading)
        case .freeRoam:
            targetAngle = setArrowModeFreeRoam(cameraHeading: mapHeading, trueHeading: trueHeading)
        case .reviewing:
            targetAngle = setArrowModeReviewing(trueHeading: trueHeading)
        }
        
        let smoothed = smoothAngleTransition(from: lastRotation, to: targetAngle)
        lastRotation = smoothed
        desiredArrowRotation = smoothed
    }

    // MARK: - Mode-Specific Arrow Angle Calculations

    /// Calculates the arrow angle when orientation mode is `.headingUp`.
    /// The arrow points straight ahead (0 degrees).
    private func setArrowModeHeadsUp() -> CLLocationDirection {
        return 0
    }

    /// Calculates the arrow angle when orientation mode is `.northUp`.
    /// The arrow points relative to the true heading normalized to [0,360).
    private func setArrowModeNorthUp(trueHeading: CLLocationDirection) -> CLLocationDirection {
        return normalizedAngle(trueHeading)
    }

    /// Calculates the arrow angle when orientation mode is `.freeRoam`.
    /// The arrow angle is the difference between true heading and map heading, normalized.
    private func setArrowModeFreeRoam(cameraHeading: CLLocationDirection, trueHeading: CLLocationDirection) -> CLLocationDirection {
        return normalizedAngle(trueHeading - cameraHeading)
    }

    /// Calculates the arrow angle when orientation mode is `.reviewing`.
    /// If the last non-free-roam orientation was `.northUp`, returns normalized true heading; otherwise 0.
    private func setArrowModeReviewing(trueHeading: CLLocationDirection) -> CLLocationDirection {
        if cameraManager.lastNonFreeRoamOrientation == .northUp {
            return normalizedAngle(trueHeading)
        } else {
            return 0
        }
    }

    // MARK: - Helper Methods

    /// Normalizes an angle to the range [0, 360).
    /// - Parameter angle: The input angle in degrees.
    /// - Returns: The angle normalized to [0, 360).
    private func normalizedAngle(_ angle: CLLocationDirection) -> CLLocationDirection {
        var result = angle.truncatingRemainder(dividingBy: 360)
        if result < 0 { result += 360 }
        return result
    }

    /// Smooths the transition between two angles, properly handling wraparound between 359 and 0 degrees.
    /// - Parameters:
    ///   - old: The previous angle.
    ///   - new: The target angle.
    /// - Returns: The smoothed angle.
    private func smoothAngleTransition(from old: CLLocationDirection, to new: CLLocationDirection) -> CLLocationDirection {
        let delta = new - old
        if abs(delta) > 180 {
            if delta > 0 {
                return old - (360 - delta)
            } else {
                return old + (360 + delta)
            }
        }
        return new
    }
}
