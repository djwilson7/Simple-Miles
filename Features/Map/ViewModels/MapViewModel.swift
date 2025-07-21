import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

//MARK: - MAP VIEW MODEL
final class MapViewModel: NSObject, ObservableObject {
    @Published var pathPoints: [CoordinateModel] = []
    @Published var currentLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition
    @Published var autoFollowEnabled: Bool = false
    @Published var manualRecenterRequested: Bool = false
    @Published var currentHeading: CLLocationDirection = 0
    @Published var currentRegion: MKCoordinateRegion?
    @Published var isUserInteracting: Bool = false
    @Published private(set) var lastCamera: MapCamera?
    @Published var travelHeading: CLLocationDirection = 0
    @Published var displayedArrowRotation: CLLocationDirection = 0

    private var hasInitializedHeading = false
    private var lastOrientationMode: MapOrientationMode = .northUp

    var trueHeading: CLLocationDirection {
        arrowHeadingStore.trueHeading
    }

    var locationIconName: String {
        switch cameraController.orientationMode {
        case .northUp, .userDefinedRotation: "location.north.line"
        case .headingUp: "location.north.line.fill"
        case .free: "circle.fill"
        }
    }

    private let arrowHeadingStore: ArrowHeadingStore
    let cameraController = MapCameraController()
    private let sessionStore: TripSessionStoringProtocol
    private let tripTrackingService: TripTrackingServiceProtocol
    private let locationService: LocationServiceProtocol
    private let zoomStore: ZoomLevelStore
    private var cancellables = Set<AnyCancellable>()

    var mapHeading: CLLocationDirection {
        lastCamera?.heading ?? 0
    }

    init(
        sessionStore: TripSessionStoringProtocol = TripSessionStore(),
        tripTrackingService: TripTrackingServiceProtocol = TripTrackingService.shared,
        locationService: LocationServiceProtocol = LocationService.shared,
        zoomStore: ZoomLevelStore = ZoomLevelStore(),
        arrowHeadingStore: ArrowHeadingStore? = nil
    ) {
        self.sessionStore = sessionStore
        self.tripTrackingService = tripTrackingService
        self.locationService = locationService
        self.zoomStore = zoomStore
        self.arrowHeadingStore = arrowHeadingStore ?? ArrowHeadingStore(headingPublisher: locationService.headingPublisher)
        self.cameraPosition = zoomStore.load().map { .region($0) } ?? .automatic
        super.init()
        cameraController.setOrientationMode(.northUp)
        bindStreams()
    }

    func recenter() {
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

        print("[MapViewModel] OrientationStateUpdate → Recenter tapped. Mode: \(next), AutoFollow: \(autoFollowEnabled)")
    }

    func updateZoomRegion(_ region: MKCoordinateRegion) {
        zoomStore.save(region: region)
        currentRegion = region
    }

    func loadPathPoints(filter type: TripType? = nil) {
        pathPoints = sessionStore.fetchAll()
            .filter { type == nil || $0.tripType == type }
            .flatMap(\.path)
    }

    private func updateCameraPosition(to coordinate: CLLocationCoordinate2D, distance: CLLocationDistance? = nil) {
        guard let location = currentLocation else { return }
        print("[MapViewModel] Updating camera position with location: \(location.coordinate)")

        let resolvedDistance = distance ?? (zoomStore.load()?.span.latitudeDelta ?? 0.02) * 111_000

        let (camera, arrowRotation) = OrientationResolver.resolve(
            userHeading: trueHeading,
            travelHeading: travelHeading,
            coordinate: coordinate,
            speed: location.speed,
            distance: resolvedDistance,
            cameraController: cameraController
        )
        print("[MapViewModel] OrientationResolver - user: \(trueHeading), cam: \(camera.heading), arrow: \(arrowRotation)")
        print("Arrow: user \(trueHeading), cam \(camera.heading), result \(arrowRotation)")

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

        print("[MapViewModel] Camera updated: \(camera)")
        self.lastCamera = MapCamera(centerCoordinate: camera.centerCoordinate, distance: camera.altitude, heading: camera.heading, pitch: camera.pitch)
        // Normalize heading delta to prevent sharp jumps near 360/0 transition
        let rotationTarget = arrowRotation
        let previous = displayedArrowRotation
        var delta = rotationTarget - previous
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        let normalizedRotation = previous + delta
        self.displayedArrowRotation = normalizedRotation
        print("[MapViewModel] Arrow rotation updated: \(normalizedRotation)")
    }

    private func updateArrowRotationOnly() {
        if cameraController.orientationMode == .userDefinedRotation {
            let userHeading = trueHeading
            let mapHeading = cameraController.currentCameraHeading
            let rotationTarget = OrientationResolver.normalizedAngle(userHeading - mapHeading)
            let previous = displayedArrowRotation
            var delta = rotationTarget - previous
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            self.displayedArrowRotation = previous + delta
            print("[MapViewModel] [ArrowOnly] → delta: \(delta), updated: \(displayedArrowRotation)")
            return
        }

        guard let location = currentLocation else { return }

        let (_, arrowRotation) = OrientationResolver.resolve(
            userHeading: trueHeading,
            travelHeading: travelHeading,
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
        print("[MapViewModel] [ArrowOnly] → delta: \(delta), updated: \(displayedArrowRotation)")
    }

    private func bindStreams() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                print("[MapViewModel] Received location: \(location.coordinate)")

                if self.currentLocation == nil {
                    self.cameraPosition = .camera(MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0))
                }

                if let previous = self.currentLocation {
                    self.travelHeading = self.calculateBearing(from: previous.coordinate, to: location.coordinate)
                }

                self.currentLocation = location

                print("[MapViewModel] OrientationStateUpdate → autoFollowEnabled: \(self.autoFollowEnabled), orientationMode: \(self.cameraController.orientationMode)")
                if autoFollowEnabled && cameraController.orientationMode != .free {
                    updateCameraPosition(to: location.coordinate)
                }
            }
            .store(in: &cancellables)

        locationService.headingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                guard let self else { return }
                print("[MapViewModel] Received heading: \(heading)")
                self.currentHeading = heading

                print("[MapViewModel] OrientationStateUpdate → headingPublisher update. autoFollow: \(self.autoFollowEnabled), orientationMode: \(self.cameraController.orientationMode)")
                switch self.cameraController.orientationMode {
                case .headingUp:
                    self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                case .northUp:
                    if self.autoFollowEnabled || !self.hasInitializedHeading {
                        self.hasInitializedHeading = true
                        self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                    }
                case .userDefinedRotation:
                    self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                case .free:
                    break
                }
                self.updateArrowRotationOnly()
            }
            .store(in: &cancellables)

        tripTrackingService.currentSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.pathPoints = $0?.path ?? []
            }
            .store(in: &cancellables)
    }

    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDirection {
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
        cameraController.updateUserDefinedCameraHeading(heading)

        if cameraController.orientationMode != .userDefinedRotation {
            cameraController.setOrientationMode(.userDefinedRotation)
            autoFollowEnabled = false
            print("[MapViewModel] OrientationStateUpdate → User rotated map. Switching to userDefinedRotation. Heading: \(heading)")
        }

        // Only used for initial positioning
        guard let location = currentLocation else { return }
        updateCameraPosition(to: location.coordinate)
    }

    /// Detects manual rotation and transitions to user-defined mode if appropriate.
    func transitionToUserDefinedIfRotated(currentCameraHeading: CLLocationDirection) {
        let delta = abs(currentCameraHeading - mapHeading).truncatingRemainder(dividingBy: 360)
        print("[MapViewModel] Transition check → mapHeading: \(mapHeading), currentHeading: \(currentCameraHeading), delta: \(delta)")
        guard delta >= 5 else { return }
        print("[MapViewModel] OrientationStateUpdate → Rotation delta: \(delta), Current Mode: \(cameraController.orientationMode)")

        switch cameraController.orientationMode {
        case .northUp, .headingUp, .userDefinedRotation:
            handleUserRotation(to: currentCameraHeading)
        case .free:
            break
        }
    }

    /// Updates the user-defined heading and arrow rotation if currently rotating.
    public func updateUserDefinedHeadingIfRotating(_ heading: CLLocationDirection) {
        print("[MapViewModel] [LiveRotation] Heading input: \(heading), TrueHeading: \(trueHeading)")
        guard cameraController.orientationMode == .userDefinedRotation else { return }
        cameraController.updateUserDefinedCameraHeading(heading)
        updateArrowRotationOnly()
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}


//MARK: - ORIENTATION RESOLVER

struct OrientationResolver {
    static func resolve(
        userHeading: CLLocationDirection,
        travelHeading: CLLocationDirection,
        coordinate: CLLocationCoordinate2D,
        speed: CLLocationSpeed,
        distance: CLLocationDistance,
        cameraController: MapCameraController
    ) -> (camera: MKMapCamera, arrowRotation: CLLocationDirection) {
        let camera = cameraController.makeCamera(
            coordinate: coordinate,
            currentHeading: userHeading,
            travelHeading: travelHeading,
            speed: speed,
            distance: distance
        )

        let arrowRotation = normalizedAngle(userHeading - camera.heading)

        return (camera, arrowRotation)
    }

    static func normalizedAngle(_ angle: CLLocationDirection) -> CLLocationDirection {
        let adjusted = fmod(angle + 360, 360)
        return adjusted < 0 ? adjusted + 360 : adjusted
    }
}


// MARK: - MAP CAMERA CONTROLLER

enum MapOrientationMode {
    case northUp
    case headingUp
    case userDefinedRotation
    case free
}

final class MapCameraController {
    private(set) var orientationMode: MapOrientationMode = .northUp
    private var userDefinedCameraHeading: CLLocationDirection = 0

    func setOrientationMode(_ mode: MapOrientationMode) {
        self.orientationMode = mode
    }

    func updateUserDefinedCameraHeading(_ heading: CLLocationDirection) {
        self.userDefinedCameraHeading = heading
    }

    var currentCameraHeading: CLLocationDirection {
        switch orientationMode {
        case .northUp:
            return 0
        case .headingUp:
            return 0
        case .free:
            return 0
        case .userDefinedRotation:
            return userDefinedCameraHeading
        }
    }

    func makeCamera(
        coordinate: CLLocationCoordinate2D,
        currentHeading: CLLocationDirection,
        travelHeading: CLLocationDirection,
        speed: CLLocationSpeed,
        distance: CLLocationDistance
    ) -> MKMapCamera {
        let heading: CLLocationDirection

        switch orientationMode {
        case .northUp:
            heading = 0
        case .headingUp:
            heading = (speed >= 2.0) ? travelHeading : currentHeading
        case .free:
            heading = currentHeading
        case .userDefinedRotation:
            heading = userDefinedCameraHeading
        }

        let camera = MKMapCamera()
        camera.centerCoordinate = coordinate
        camera.heading = heading
        camera.pitch = 0
        camera.altitude = distance
        return camera
    }

    private func shortestRotation(from: CLLocationDirection, to: CLLocationDirection) -> CLLocationDirection {
        let delta = fmod(to - from + 540, 360) - 180
        return from + delta
    }
}

//MARK: - ARROW HEADING STORE

final class ArrowHeadingStore: ObservableObject {
    @Published private(set) var trueHeading: CLLocationDirection = 0

    private var cancellable: AnyCancellable?

    init(headingPublisher: AnyPublisher<CLLocationDirection, Never>) {
        cancellable = headingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.trueHeading, on: self)
    }
}
