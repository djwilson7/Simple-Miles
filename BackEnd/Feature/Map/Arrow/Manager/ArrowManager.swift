import Foundation
import Combine
import CoreLocation
import MapKit

/// Coordinates camera orientation, map heading, and true heading to produce a desired
/// on-map arrow rotation suitable for UI display.
@MainActor
final class ArrowHeadingManager: ObservableObject {

    // MARK: - Singleton
    static let shared = ArrowHeadingManager()

    // MARK: - Dependencies
    private let cameraManager = CameraManager.shared
    private let locationPredictor = LocationPredictionManager.shared
    private let travelStateManager = TravelStateManager.shared

    // MARK: - Published State (Outputs)
    @Published var desiredArrowRotation: CLLocationDirection = 0

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var lastRotation: CLLocationDirection = 0
    private var travelState: TravelState = .idle

    // MARK: - Init
    private init() {
        bind()
    }

    // MARK: - Bindings (Streams wiring)
    private func bind() {
        travelStateManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: \.travelState, on: self)
            .store(in: &cancellables)

        Publishers
            .CombineLatest4(
                cameraManager.$currentHeading,
                locationPredictor.$activeHeading,
                cameraManager.$mapHeading,
                cameraManager.$orientationMode
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cameraHeading, activeHeading, mapHeading, orientationMode in
                guard let self = self else { return }
                self.updateArrowRotation(
                    cameraHeading: cameraHeading,
                    trueHeading: activeHeading ?? 0,
                    mapHeading: mapHeading,
                    orientation: orientationMode
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    func updateArrowRotation(
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

    private func setArrowModeHeadsUp() -> CLLocationDirection {
        return 0
    }

    private func setArrowModeNorthUp(trueHeading: CLLocationDirection) -> CLLocationDirection {
        return normalizedAngle(trueHeading)
    }

    private func setArrowModeFreeRoam(cameraHeading: CLLocationDirection, trueHeading: CLLocationDirection) -> CLLocationDirection {
        return normalizedAngle(trueHeading - cameraHeading)
    }

    private func setArrowModeReviewing(trueHeading: CLLocationDirection) -> CLLocationDirection {
        if cameraManager.lastNonFreeRoamOrientation == .northUp {
            return normalizedAngle(trueHeading)
        } else {
            return 0
        }
    }

    private func normalizedAngle(_ angle: CLLocationDirection) -> CLLocationDirection {
        var result = angle.truncatingRemainder(dividingBy: 360)
        if result < 0 { result += 360 }
        return result
    }

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

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
