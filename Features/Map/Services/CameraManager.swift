import MapKit
import CoreLocation
import Combine
import SwiftUI

enum CameraOrientationMode {
    case northUp
    case headingUp
}

final class CameraManager: NSObject, ObservableObject {

    // MARK: - Public Published State
    @Published var orientationMode: CameraOrientationMode = .northUp
    @Published var currentHeading: CLLocationDirection = 0
    @Published var desiredCameraPosition: MapCamera? = nil

    // MARK: - Private Properties
    private var travelLocationPredictor: TravelLocationPredictor
    private var userZoomLevel: CLLocationDistance?
    private let headingTolerance: CLLocationDirection = 2.0
    private var lastProgrammaticHeading: CLLocationDirection = 0
    private var autoZoomEnabled: Bool = true
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(travelLocationPredictor: TravelLocationPredictor) {
        self.travelLocationPredictor = travelLocationPredictor
        super.init()
        bindTravelMotionManager()
    }

    // MARK: - Binding
    private func bindTravelMotionManager() {
        travelLocationPredictor.$activeLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateCameraCenter(for: location)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(travelLocationPredictor.$activeHeading, $orientationMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading, mode in
                guard let self = self else { return }
                guard mode == .headingUp else { return }

                self.updateCameraHeading(to: heading)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Controls

    func setOrientationMode(_ mode: CameraOrientationMode) {
        if orientationMode == mode {
            orientationMode = (mode == .northUp) ? .headingUp : .northUp
        } else {
            orientationMode = mode
        }

        if let location = travelLocationPredictor.activeLocation {
            updateCameraCenter(for: location)
        }

        if orientationMode == .headingUp {
            let heading = travelLocationPredictor.activeHeading
            updateCameraHeading(to: heading)
        }
    }

    func enableAutoZoom(_ enabled: Bool) {
        autoZoomEnabled = enabled
    }

    func setUserZoomLevel(_ distance: CLLocationDistance) {
        userZoomLevel = distance
    }

    func resetToNorth() {
        orientationMode = .northUp
        lastProgrammaticHeading = 0
        currentHeading = 0
        if let location = travelLocationPredictor.activeLocation {
            updateCameraCenter(for: location)
        }
    }

    // MARK: - Core Camera Update

    public func updateCameraCenter(for location: CLLocation) {
        let heading: CLLocationDirection
        switch orientationMode {
        case .northUp:
            heading = 0
        case .headingUp:
            heading = travelLocationPredictor.activeHeading
        }

        currentHeading = heading
        lastProgrammaticHeading = heading

        let altitude = userZoomLevel ?? 1500

        desiredCameraPosition = MapCamera(
            centerCoordinate: location.coordinate,
            distance: altitude,
            heading: heading,
            pitch: 0
        )
    }

    private func updateCameraHeading(to heading: CLLocationDirection) {
        guard let coordinate = travelLocationPredictor.activeLocation?.coordinate else { return }
        currentHeading = heading
        lastProgrammaticHeading = heading

        let altitude = userZoomLevel ?? 1500

        desiredCameraPosition = MapCamera(
            centerCoordinate: coordinate,
            distance: altitude,
            heading: heading,
            pitch: 0
        )
    }

    func currentZoomLevel() -> CLLocationDistance {
        userZoomLevel ?? 1500
    }

    func updateZoomLevel(_ altitude: CLLocationDistance) {
        userZoomLevel = altitude
    }
}
