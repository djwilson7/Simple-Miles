import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI

@MainActor
final class CameraManager: NSObject, ObservableObject {
    static let shared = CameraManager()

    @Published var orientationMode: CameraOrientationMode = .northUp
    @Published var currentHeading: CLLocationDirection = 0
    @Published var desiredCameraPosition: MapCamera? = nil
    @Published var mapHeading: CLLocationDirection = 0

    private var lastLocation : LocationPoint?
    private var lastHeading : CLLocationDirection?
    
    private let locationPredictor = LocationPredictionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    var lastNonFreeRoamOrientation: CameraOrientationMode = .northUp

    // MARK: - Camera altitude persistence
    private let defaultAltitude: CLLocationDistance = 1500

    func saveUserCameraDistance(_ distance: CLLocationDistance) {
        // Guard against non-positive distances, avoid writing bad values.
        guard distance > 0 else { return }
        UserDefaults.standard.set(distance, forKey: UserDefaultKeys.cameraAltitude.rawValue)
    }

    // Internal so a temporary shim (CameraDistance) can forward calls during migration.
    func loadSavedCameraDistance() -> CLLocationDistance? {
        let value = UserDefaults.standard.double(forKey: UserDefaultKeys.cameraAltitude.rawValue)
        return value > 0 ? value : nil
    }

    private func currentAltitude() -> CLLocationDistance {
        loadSavedCameraDistance() ?? defaultAltitude
    }

    private override init() {
        super.init()
        bindTravelMotionManager()

    }

    private func bindTravelMotionManager() {
        Publishers.CombineLatest3(
            locationPredictor.$activeLocation.compactMap { $0 },
            locationPredictor.$activeHeading,
            $orientationMode
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] location, heading, orientation in
            self?.handleCameraUpdate(location: location, heading: heading, orientation: orientation)
        }
        .store(in: &cancellables)
    }
    
    func updateOrientationMode(_ newOrientation: CameraOrientationMode) {
        if orientationMode == .northUp || orientationMode == .headingUp {
            lastNonFreeRoamOrientation = orientationMode
        }
        orientationMode = newOrientation
        
        if newOrientation == .freeRoam { }
    }
    
    private func handleCameraUpdate(
        location: LocationPoint,
        heading: CLLocationDirection,
        orientation: CameraOrientationMode
    ) {
        lastLocation = location
        switch orientation {
        case .northUp: setCameraToNorthUp(location)
        case .headingUp: setCameraToHeadingUp(location, heading)
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
    
    func setCameraToFreeRoam(heading: CLLocationDirection? = nil) {
        if let heading = heading {
            mapHeading = heading
        }
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

}
