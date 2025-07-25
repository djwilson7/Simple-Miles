import Foundation
import Combine
import CoreLocation
import MapKit

final class ArrowHeadingManager: ObservableObject {

    // MARK: - Public Published State
    @Published var displayedArrowRotation: CLLocationDirection = 0

    // MARK: - Private
    private let cameraManager: CameraManager
    private let travelLocationPredictor: TravelLocationPredictor
    private let travelStateManager: TravelStateManager
    private var cancellables = Set<AnyCancellable>()
    private var lastRotation: CLLocationDirection = 0
    private var travelState: TravelStateManager.TravelState = .idle

    /// Initialize with the shared camera and travel motion managers
    init(cameraManager: CameraManager, travelLocationPredictor: TravelLocationPredictor, travelStateManager: TravelStateManager) {
        self.cameraManager = cameraManager
        self.travelLocationPredictor = travelLocationPredictor
        self.travelStateManager = travelStateManager
        bind()
    }

    /// Bind to camera heading, travel heading, and orientation mode updates
    private func bind() {
        travelStateManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: \.travelState, on: self)
            .store(in: &cancellables)

        Publishers
            .CombineLatest3(cameraManager.$currentHeading, travelLocationPredictor.$activeHeading, cameraManager.$orientationMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cameraHeading, activeHeading, orientation in
                self?.updateArrowRotation(cameraHeading: cameraHeading, trueHeading: activeHeading, orientation: orientation)
            }
            .store(in: &cancellables)
    }

    /// Compute and normalize the arrow rotation based on camera and device heading and orientation mode
    private func updateArrowRotation(cameraHeading: CLLocationDirection, trueHeading: CLLocationDirection, orientation: CameraOrientationMode) {
        let targetRotation: CLLocationDirection

        switch orientation {
        case .headingUp:
            targetRotation = 0
        case .northUp:
            targetRotation = normalizedAngle(trueHeading - cameraHeading)
        }

        let smoothedRotation = smoothAngleTransition(from: lastRotation, to: targetRotation)
        lastRotation = smoothedRotation
        displayedArrowRotation = smoothedRotation

    }

    /// Normalize an angle to [0, 360)
    private func normalizedAngle(_ angle: CLLocationDirection) -> CLLocationDirection {
        var result = angle.truncatingRemainder(dividingBy: 360)
        if result < 0 { result += 360 }
        return result
    }

    /// Smooths the transition between angles, handling the 359 <-> 0 wraparound
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
