import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

final class MapViewModel: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition
    @Published var autoFollowEnabled: Bool = false
    @Published var manualRecenterRequested: Bool = false
    @Published var currentHeading: CLLocationDirection = 0
    @Published var currentRegion: MKCoordinateRegion?
    @Published var isUserInteracting: Bool = false
    @Published private(set) var lastCamera: MapCamera?
    @Published var displayedArrowRotation: CLLocationDirection = 0
    @Published var currentSegment: [CLLocationCoordinate2D] = []
    private var traceOrigin: CLLocationCoordinate2D?

    private var hasInitializedHeading = false
    private var lastOrientationMode: MapOrientationMode = .northUp
    private let traceStore: TripTraceStore

    var locationIconName: String {
        switch cameraController.orientationMode {
        case .northUp, .userDefinedRotation: "location.north.line"
        case .headingUp: "location.north.line.fill"
        case .free: "circle.fill"
        }
    }

    let cameraController = MapCameraController()
    private let locationManager: LocationManager
    private let zoomStore: ZoomLevelStore
    private var cancellables = Set<AnyCancellable>()

    var mapHeading: CLLocationDirection {
        lastCamera?.heading ?? 0
    }

    init(
        locationManager: LocationManager,
        zoomStore: ZoomLevelStore = ZoomLevelStore(),
        traceStore: TripTraceStore
    ) {
        print("[MapViewModel] (init) - Initializing map view model and binding location/heading streams")
        self.locationManager = locationManager
        self.zoomStore = zoomStore
        self.traceStore = traceStore
        self.cameraPosition = zoomStore.load().map { .region($0) } ?? .automatic
        super.init()
        cameraController.setOrientationMode(.northUp)
        bindStreams()
    }

    func recenter() {
        print("[MapViewModel] (recenter) - Recenter triggered; updating camera orientation and position")
        guard let location = currentLocation else { return }

        autoFollowEnabled = true

        let current = cameraController.orientationMode
        let next: MapOrientationMode
        if current == .free {
            next = .headingUp
        } else {
            next = (current == .headingUp) ? .northUp : .headingUp
        }
        cameraController.setOrientationMode(next)

        let span = zoomStore.load()?.span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let distance = span.latitudeDelta * 111_000
        updateCameraPosition(to: location.coordinate, distance: distance)
    }

    func updateZoomRegion(_ region: MKCoordinateRegion) {
        print("[MapViewModel] (updateZoomRegion) - Zoom region updated and saved")
        zoomStore.save(region: region)
        currentRegion = region
    }


    private func updateCameraPosition(to coordinate: CLLocationCoordinate2D, distance: CLLocationDistance? = nil) {
        //print("[MapViewModel] (updateCameraPosition) - Updating camera based on location and heading")
        guard let location = currentLocation else { return }
        
        let resolvedDistance = distance ?? (zoomStore.load()?.span.latitudeDelta ?? 0.02) * 111_000

        let (camera, arrowRotation) = OrientationResolver.resolve(
            userHeading: locationManager.trueHeading,
            travelHeading: locationManager.travelHeading,
            coordinate: coordinate,
            speed: location.speed,
            distance: resolvedDistance,
            cameraController: cameraController
        )
        let newCameraPosition = MapCamera(centerCoordinate: camera.centerCoordinate, distance: camera.altitude, heading: camera.heading, pitch: camera.pitch)

        if (cameraController.orientationMode == .headingUp && lastOrientationMode == .northUp) ||
           (cameraController.orientationMode == .northUp && lastOrientationMode == .headingUp) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.cameraPosition = .camera(newCameraPosition)
            }
        } else {
            self.cameraPosition = .camera(newCameraPosition)
        }

        self.lastOrientationMode = cameraController.orientationMode

        self.lastCamera = MapCamera(centerCoordinate: camera.centerCoordinate, distance: camera.altitude, heading: camera.heading, pitch: camera.pitch)
        // Normalize heading delta to prevent sharp jumps near 360/0 transition
        let rotationTarget = arrowRotation
        let previous = displayedArrowRotation
        var delta = rotationTarget - previous
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        let normalizedRotation = previous + delta
        self.displayedArrowRotation = normalizedRotation
    }

    private func updateArrowRotationOnly() {
        //print("[MapViewModel] (updateArrowRotationOnly) - Updating rotation of travel arrow based on heading")
        if cameraController.orientationMode == .userDefinedRotation {
            let userHeading = locationManager.trueHeading
            let mapHeading = cameraController.currentCameraHeading
            let rotationTarget = OrientationResolver.normalizedAngle(userHeading - mapHeading)
            let previous = displayedArrowRotation
            var delta = rotationTarget - previous
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            self.displayedArrowRotation = previous + delta
            return
        }

        guard let location = currentLocation else { return }

        let (_, arrowRotation) = OrientationResolver.resolve(
            userHeading: locationManager.trueHeading,
            travelHeading: locationManager.travelHeading,
            coordinate: location.coordinate,
            speed: location.speed,
            distance: (zoomStore.load()?.span.latitudeDelta ?? 0.02) * 111_000,
            cameraController: cameraController
        )

        let previous = displayedArrowRotation
        var delta = arrowRotation - previous
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        self.displayedArrowRotation = previous + delta
    }

    private func bindStreams() {
        print("[MapViewModel] (bindStreams) - Binding location and heading streams")
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self, let location else { return }

                print("[MapViewModel] (bindStreams - currentLocation) - Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")

                if self.currentLocation == nil {
                    if let savedRegion = zoomStore.load() {
                        self.cameraPosition = .region(savedRegion)
                    } else {
                        self.cameraPosition = .camera(MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0))
                    }
                }

                self.currentLocation = location
                print("[MapViewModel] (bindStreams - currentLocation) - Updated currentLocation.")

                if autoFollowEnabled && cameraController.orientationMode != .free {
                    updateCameraPosition(to: location.coordinate)
                    print("[MapViewModel] (bindStreams - currentLocation) - Camera position updated.")
                }
            }
            .store(in: &cancellables)

        locationManager.$trueHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                //print("[MapViewModel] (bindStreams - trueHeading) - Received true heading: \(heading)")
                guard let self else { return }
                self.currentHeading = heading
                //print("[MapViewModel] (bindStreams - trueHeading) - Updated current heading.")

                switch self.cameraController.orientationMode {
                case .headingUp:
                    self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                    //print("[MapViewModel] (bindStreams - trueHeading) - Camera position updated based on orientation mode.")
                case .northUp:
                    if self.autoFollowEnabled || !self.hasInitializedHeading {
                        self.hasInitializedHeading = true
                        self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                        //print("[MapViewModel] (bindStreams - trueHeading) - Camera position updated based on orientation mode.")
                    }
                case .userDefinedRotation:
                    self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                    //print("[MapViewModel] (bindStreams - trueHeading) - Camera position updated based on orientation mode.")
                case .free:
                    break
                }
                self.updateArrowRotationOnly()
                //print("[MapViewModel] (bindStreams - trueHeading) - Arrow rotation updated.")
            }
            .store(in: &cancellables)

        traceStore.$lastSegment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] segment in
                guard let self, let segment else { return }
                self.currentSegment = [segment.0, segment.1]
            }
            .store(in: &cancellables)
    }

    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDirection {
        //print("[MapViewModel] (calculateBearing) - Calculating bearing between two coordinates")
        let fromLat = from.latitude.degreesToRadians
        let fromLon = from.longitude.degreesToRadians
        let toLat = to.latitude.degreesToRadians
        let toLon = to.longitude.degreesToRadians

        let dLon = toLon - fromLon
        let y = sin(dLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLon)
        let radiansBearing = atan2(y, x)
        var degrees = radiansBearing.radiansToDegrees
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    func handleUserRotation(to heading: CLLocationDirection) {
        //print("[MapViewModel] (handleUserRotation) - User rotated map manually; updating camera and disabling auto-follow")
        cameraController.updateUserDefinedCameraHeading(heading)

        if cameraController.orientationMode != .userDefinedRotation {
            cameraController.setOrientationMode(.userDefinedRotation)
            autoFollowEnabled = false
        }

        // Only used for initial positioning
        guard let location = currentLocation else { return }
        updateCameraPosition(to: location.coordinate)
    }

    /// Detects manual rotation and transitions to user-defined mode if appropriate.
    func transitionToUserDefinedIfRotated(currentCameraHeading: CLLocationDirection) {
        //print("[MapViewModel] (transitionToUserDefinedIfRotated) - Evaluating manual rotation to switch orientation mode")
        let delta = abs(currentCameraHeading - mapHeading).truncatingRemainder(dividingBy: 360)
        guard delta >= 5 else { return }

        switch cameraController.orientationMode {
        case .northUp, .headingUp, .userDefinedRotation:
            handleUserRotation(to: currentCameraHeading)
        case .free:
            break
        }
    }

    /// Updates the user-defined heading and arrow rotation if currently rotating.
    public func updateUserDefinedHeadingIfRotating(_ heading: CLLocationDirection) {
        //print("[MapViewModel] (updateUserDefinedHeadingIfRotating) - Updating heading and arrow when user is rotating map")
        guard cameraController.orientationMode == .userDefinedRotation else { return }
        cameraController.updateUserDefinedCameraHeading(heading)
        updateArrowRotationOnly()
    }
}
