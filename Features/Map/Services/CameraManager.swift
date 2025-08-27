import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI

final class CameraManager: NSObject, ObservableObject {

    // MARK: - Singleton Instance
    static let shared = CameraManager()

    // MARK: - Public Published State
    @Published var orientationMode: CameraOrientationMode = .northUp
    @Published var currentHeading: CLLocationDirection = 0
    @Published var desiredCameraPosition: MapCamera? = nil
    
    /// The authoritative published heading for the map orientation in free roam mode.
    /// Other managers (like ArrowHeadingManager) can subscribe to this to track user-controlled map heading.
    @Published var mapHeading: CLLocationDirection = 0

    // MARK: - Private Properties
    private var lastLocation : LocationPoint?
    private var lastHeading : CLLocationDirection?
    
    private let travelLocationPredictor = TravelLocationPredictor.shared
    private var cancellables = Set<AnyCancellable>()
    
    var lastNonFreeRoamOrientation: CameraOrientationMode = .northUp

    // MARK: - Initialization
    private override init() {
        super.init()
        bindTravelMotionManager()

    }

    // MARK: - Binding
    private func bindTravelMotionManager() {
        Publishers.CombineLatest3(
            travelLocationPredictor.$activeLocation.compactMap { $0 },
            travelLocationPredictor.$activeHeading,
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
        
        if newOrientation == .freeRoam {
            // When entering free roam, mapHeading should be set by the coordinator or view model
            // calling setCameraToFreeRoam(heading:) with the latest map heading.
            // This method does not call setCameraToFreeRoam itself to avoid unwanted side effects.
        }
    }
    
    /// Saves the provided camera altitude (distance) if needed.
    /// - Parameter distance: The new camera altitude to save
    public func saveUserCameraDistance(_ distance: CLLocationDistance) {
        CameraDistance.shared.saveDistance(distance)
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
            // No automatic camera update in free roam mode.
            break
        case .reviewing:
            // No op for now
            break
        }
    }
    
    // MARK: - Core Camera Update

    /// Updates the published desiredCameraPosition based on a CameraModel (base or extended)
    private func publishCameraPosition(from cameraModel: CameraModel) {
        desiredCameraPosition = MapCamera(
            centerCoordinate: cameraModel.center,
            distance: cameraModel.altitude,
            heading: cameraModel.heading,
            pitch: cameraModel.pitch
        )
    }

    /// Sets the camera to "north up" orientation: heading fixed to north, using current location and zoom.
    private func setCameraToNorthUp(_ location: LocationPoint) {
        let altitude = CameraDistance.shared.loadDistance() ?? 1500
        let cameraModel = CameraModel(
            center: location.coordinate,
            altitude: altitude,
            heading: 0, // North
            pitch: 0
        )
        publishCameraPosition(from: cameraModel)
    }
    
    /// Sets the camera to "heading up" orientation: heading matches user's active heading, using current location and zoom.
    private func setCameraToHeadingUp(
        _ location: LocationPoint,
        _ heading: CLLocationDirection
    ) {
        let altitude = CameraDistance.shared.loadDistance() ?? 1500
        let cameraModel = CameraModel(
            center: location.coordinate,
            altitude: altitude,
            heading: heading, // Match user heading
            pitch: 0
        )
        publishCameraPosition(from: cameraModel)
    }
    
    /// Sets the camera to "free roam" mode: disables programmatic camera updating, user can control freely.
    /// - Parameter heading: Optional heading to set as the authoritative mapHeading for free roam orientation.
    func setCameraToFreeRoam(heading: CLLocationDirection? = nil) {
        if let heading = heading {
            mapHeading = heading
        }
    }
    
    /// Publishes a default camera centered on the last known location using saved altitude.
    private func publishFallbackToLastLocation() {
        guard let last = lastLocation else { return }
        let altitude = CameraDistance.shared.loadDistance() ?? 1500
        let cameraModel = CameraModel(
            center: last.coordinate,
            altitude: altitude,
            heading: 0,
            pitch: 0
        )
        publishCameraPosition(from: cameraModel)
    }
    
    /// Sets the camera to review mode: fits the camera to the provided path using the path-fitting utility.
    func setCameraToReview(path: [CLLocationCoordinate2D]) {
        // If there is no path, use last known location
        guard !path.isEmpty else {
            publishFallbackToLastLocation()
            return
        }

        // Try to fit the path; if that fails, fall back to last location
        if let cameraModel = CameraModel.forPath(path) {
            publishCameraPosition(from: cameraModel)
        } else {
            publishFallbackToLastLocation()
        }
    }
          
    /// Reverts camera orientation back to the last non-free-roam mode.
    public func resetOrientation() {
        orientationMode = lastNonFreeRoamOrientation
    }

}
