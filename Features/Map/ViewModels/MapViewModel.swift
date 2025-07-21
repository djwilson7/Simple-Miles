import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

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

    var trueHeading: CLLocationDirection {
        arrowHeadingStore.trueHeading
    }

    @Published var orientationMode: MapOrientationMode = .northUp

    var locationIconName: String {
        switch orientationMode {
        case .northUp, .userDefinedRotation: "location.north.line"
        case .headingUp: "location.north.line.fill"
        case .free: "circle.fill"
        }
    }

    private let arrowHeadingStore: ArrowHeadingStore
    private let cameraController: MapCameraController
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
        arrowHeadingStore: ArrowHeadingStore? = nil,
        cameraController: MapCameraController = MapCameraController()
    ) {
        self.sessionStore = sessionStore
        self.tripTrackingService = tripTrackingService
        self.locationService = locationService
        self.zoomStore = zoomStore
        self.arrowHeadingStore = arrowHeadingStore ?? ArrowHeadingStore(headingPublisher: locationService.headingPublisher)
        self.cameraController = cameraController
        self.cameraPosition = zoomStore.load().map { .region($0) } ?? .automatic
        super.init()
        bindStreams()
    }

    func recenter() {
        guard let location = currentLocation else { return }

        autoFollowEnabled = true

        if orientationMode == .free {
            orientationMode = .headingUp
        } else {
            orientationMode = (orientationMode == .headingUp) ? .northUp : .headingUp
        }

        cameraController.setOrientationMode(orientationMode)

        let span = zoomStore.load()?.span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let distance = span.latitudeDelta * 111_000
        updateCameraPosition(to: location.coordinate, distance: distance)
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

        let resolvedDistance = distance ?? (zoomStore.load()?.span.latitudeDelta ?? 0.02) * 111_000

        let (camera, arrowRotation) = OrientationResolver.resolve(
            userHeading: trueHeading,
            travelHeading: travelHeading,
            coordinate: coordinate,
            speed: location.speed,
            distance: resolvedDistance,
            cameraController: cameraController
        )
        print("Arrow: user \(trueHeading), cam \(camera.heading), result \(arrowRotation)")
        self.cameraPosition = .camera(MapCamera(centerCoordinate: camera.centerCoordinate, distance: camera.altitude, heading: camera.heading, pitch: camera.pitch))
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

    private func bindStreams() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }

                if self.currentLocation == nil {
                    self.cameraPosition = .camera(MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0))
                }

                if let previous = self.currentLocation {
                    self.travelHeading = self.calculateBearing(from: previous.coordinate, to: location.coordinate)
                }

                self.currentLocation = location

                if autoFollowEnabled {
                    if orientationMode != .free {
                        updateCameraPosition(to: location.coordinate)
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.cameraPosition = .automatic
                        }
                    }
                }
            }
            .store(in: &cancellables)

        locationService.headingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                guard let self else { return }
                self.currentHeading = heading

                switch self.orientationMode {
                case .headingUp, .northUp:
                    if self.autoFollowEnabled {
                        self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                    }
                case .userDefinedRotation:
                    self.updateCameraPosition(to: self.currentLocation?.coordinate ?? .init())
                case .free:
                    break
                }
            }
            .store(in: &cancellables)

        tripTrackingService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if $0 == .recording { self?.autoFollowEnabled = true }
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

        if orientationMode != .userDefinedRotation {
            orientationMode = .userDefinedRotation
            cameraController.setOrientationMode(.free)
            autoFollowEnabled = false
        }

        updateCameraPosition(to: currentLocation?.coordinate ?? .init())
    }

    /// Detects manual rotation and transitions to user-defined mode if appropriate.
    func transitionToUserDefinedIfRotated(currentCameraHeading: CLLocationDirection) {
        let delta = abs(currentCameraHeading - mapHeading).truncatingRemainder(dividingBy: 360)
        if delta < 5 { return }

        switch orientationMode {
        case .northUp, .headingUp:
            handleUserRotation(to: currentCameraHeading)
        case .free, .userDefinedRotation:
            break
        }
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
