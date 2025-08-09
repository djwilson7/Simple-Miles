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

    // MARK: - Private Properties
    private var lastLocation : CLLocation?
    private var lastHeading : CLLocationDirection?
    
    private let travelLocationPredictor = TravelLocationPredictor.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var lastNonFreeRoamOrientation: CameraOrientationMode = .northUp

    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    /// Call this method after shared instance creation to start bindings.
    public func initialize() {
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
    }
    
    /// Saves the provided camera altitude (distance) if needed.
    /// - Parameter distance: The new camera altitude to save
    public func saveUserCameraDistance(_ distance: CLLocationDistance) {
        CameraDistance.shared.saveDistance(distance)
    }
    
    private func handleCameraUpdate(
        location: CLLocation,
        heading: CLLocationDirection,
        orientation: CameraOrientationMode
    ) {
        switch orientation {
        case .northUp: setCameraToNorthUp(location)
        case .headingUp: setCameraToHeadingUp(location, heading)
        case .freeRoam:
            //no op for now
            print("Entered Free Roam, No Op")
        case .reviewing:
            //no op for now
            print("Entered Reviewing, No Op")
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
    private func setCameraToNorthUp(_ location: CLLocation) {
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
        _ location: CLLocation,
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
    private func setCameraToFreeRoam() {
        //no op -> we save the last orientaion mode and revert when we exit
        //placeholder incase we want to create alt ops down the line.
    }
    
    /// Sets the camera to review mode: fits the camera to the provided path using the path-fitting utility.
    func setCameraToReview(path: [CLLocationCoordinate2D]) {
        publishCameraPosition(from: CameraModel.forPath(path))
    }
    
    /// Reverts camera orientation back to the last non-free-roam mode.
    public func resetOrientation() {
        orientationMode = lastNonFreeRoamOrientation
    }

}
