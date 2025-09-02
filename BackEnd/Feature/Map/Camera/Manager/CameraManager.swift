import MapKit
import CoreLocation
import Combine
import SwiftUI

/// Coordinates location, heading, and orientation to produce a desired MapCamera for UI consumption.
@MainActor
final class CameraManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = CameraManager()

    // MARK: - Dependencies
    private let locationPredictor = LocationPredictionManager.shared

    // MARK: - Published State (Outputs)
    @Published var orientationMode: CameraOrientationMode = .northUp
    @Published var currentHeading: CLLocationDirection = 0
    @Published var desiredCameraPosition: MapCamera? = nil
    @Published var mapHeading: CLLocationDirection = 0

    // MARK: - Private State
    private var lastLocation: LocationPoint?
    private var cancellables = Set<AnyCancellable>()
    var lastNonFreeRoamOrientation: CameraOrientationMode = .northUp

    // MARK: - Configuration
    private let defaultAltitude: CLLocationDistance = 1500

    // MARK: - Init
    private override init() {
        super.init()
        bindTravelMotionManager()
    }

    // MARK: - Public API (Intents)
    func saveUserCameraDistance(_ distance: CLLocationDistance) {
        guard distance > 0 else { return }
        UserDefaults.standard.set(distance, forKey: UserDefaultKeys.cameraAltitude.rawValue)
    }

    func loadSavedCameraDistance() -> CLLocationDistance? {
        let value = UserDefaults.standard.double(forKey: UserDefaultKeys.cameraAltitude.rawValue)
        return value > 0 ? value : nil
    }

    func updateOrientationMode(_ newOrientation: CameraOrientationMode) {
        if orientationMode == .northUp || orientationMode == .headingUp {
            lastNonFreeRoamOrientation = orientationMode
        }
        orientationMode = newOrientation

        if newOrientation == .freeRoam {
            // Intentionally left for future behavior when entering Free Roam.
        }
    }

    func setCameraToFreeRoam(heading: CLLocationDirection? = nil) {
        if let heading {
            mapHeading = heading
        }
    }

    func setCameraToReview(path: [CLLocationCoordinate2D]) {
        guard !path.isEmpty else {
            publishFallbackToLastLocation()
            return
        }

        if let cameraModel = CameraModel.forPath(path) {
            publishCameraPosition(from: cameraModel)
        } else {
            publishFallbackToLastLocation()
        }
    }

    public func resetOrientation() {
        orientationMode = lastNonFreeRoamOrientation
    }

    // MARK: - Bindings (Streams wiring)
    private func bindTravelMotionManager() {
        Publishers.CombineLatest3(
            locationPredictor.$activeLocation.compactMap { $0 },
            locationPredictor.$activeHeading,
            $orientationMode
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] location, heading, orientation in
            // Combine’s sink closure is @Sendable; hop to MainActor before touching MainActor-isolated self.
            Task { @MainActor in
                guard let self else { return }
                self.handleCameraUpdate(location: location, heading: heading, orientation: orientation)
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    private func currentAltitude() -> CLLocationDistance {
        loadSavedCameraDistance() ?? defaultAltitude
    }

    private func handleCameraUpdate(
        location: LocationPoint,
        heading: CLLocationDirection,
        orientation: CameraOrientationMode
    ) {
        lastLocation = location
        currentHeading = heading

        switch orientation {
        case .northUp:
            setCameraToNorthUp(location)
        case .headingUp:
            setCameraToHeadingUp(location, heading)
        case .freeRoam:
            break
        case .reviewing:
            break
        }
    }

    private func publishCameraPosition(from cameraModel: CameraModel) {
        desiredCameraPosition = MapCamera(
            centerCoordinate: cameraModel.center,
            distance: cameraModel.altitude,
            heading: cameraModel.heading,
            pitch: cameraModel.pitch
        )
    }

    private func setCameraToNorthUp(_ location: LocationPoint) {
        let altitude = currentAltitude()
        let cameraModel = CameraModel(
            center: location.coordinate,
            altitude: altitude,
            heading: 0,
            pitch: 0
        )
        publishCameraPosition(from: cameraModel)
    }

    private func setCameraToHeadingUp(
        _ location: LocationPoint,
        _ heading: CLLocationDirection
    ) {
        let altitude = currentAltitude()
        let cameraModel = CameraModel(
            center: location.coordinate,
            altitude: altitude,
            heading: heading,
            pitch: 0
        )
        publishCameraPosition(from: cameraModel)
    }

    private func publishFallbackToLastLocation() {
        guard let last = lastLocation else { return }
        let altitude = currentAltitude()
        let cameraModel = CameraModel(
            center: last.coordinate,
            altitude: altitude,
            heading: 0,
            pitch: 0
        )
        publishCameraPosition(from: cameraModel)
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
