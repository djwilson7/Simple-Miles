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
    @Published private(set) var lastCamera: MapCamera? = nil
        
    enum MapOrientationMode {
        case northUp
        case headingUp
        case free
    }

    @Published var orientationMode: MapOrientationMode = .northUp
    
    var locationIconName: String {
        switch orientationMode {
        case .northUp:
            return "location.north.line"
        case .headingUp:
            return "location.north.line.fill"
        case .free:
            return "circle.fill"
        }
    }

    private let sessionStore: TripSessionStoringProtocol
    private let tripTrackingService: TripTrackingServiceProtocol
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var mapHeading: CLLocationDirection {
        lastCamera?.heading ?? 0
    }

    init(
        sessionStore: TripSessionStoringProtocol = TripSessionStore(),
        tripTrackingService: TripTrackingServiceProtocol = TripTrackingService.shared,
        locationService: LocationServiceProtocol = LocationService.shared
    ) {
        self.sessionStore = sessionStore
        self.tripTrackingService = tripTrackingService
        self.locationService = locationService
        self.cameraPosition = .automatic
        super.init()
        bindLiveSession()
        bindTripStatus()
        bindLocationStream()
    }

    func recenter() {
        guard let location = currentLocation else { return }

        autoFollowEnabled = true

        if orientationMode == .free {
            orientationMode = .headingUp
        } else {
            orientationMode = (orientationMode == .headingUp) ? .northUp : .headingUp
        }

        updateCameraPosition(to: location.coordinate)
    }

    private func bindLocationStream() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }

                if self.currentLocation == nil {
                    self.cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 500,
                            heading: 0,
                            pitch: 0
                        )
                    )
                }

                self.currentLocation = location

                if self.autoFollowEnabled {
                    if self.orientationMode != .free {
                        self.updateCameraPosition(to: location.coordinate)
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
            .assign(to: &$currentHeading)
    }

    private func bindTripStatus() {
        tripTrackingService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .recording {
                    self?.autoFollowEnabled = true
                }
            }
            .store(in: &cancellables)
    }

    private func updateCameraPosition(to coordinate: CLLocationCoordinate2D) {
        switch orientationMode {
        case .headingUp, .northUp:
            let heading = (orientationMode == .headingUp) ? currentHeading : 0
            let camera = MapCamera(
                centerCoordinate: coordinate,
                distance: 500,
                heading: heading,
                pitch: 0
            )
            withAnimation(.easeInOut(duration: 0.5)) {
                self.cameraPosition = .camera(camera)
                self.lastCamera = camera
            }

        case .free:
            withAnimation(.easeInOut(duration: 0.5)) {
                self.cameraPosition = .automatic
                self.lastCamera = nil
            }
        }
    }

    func loadPathPoints(filter type: TripType? = nil) {
        let sessions = sessionStore.fetchAll()
        let points = sessions
            .filter { type == nil || $0.tripType == type }
            .flatMap { $0.path }

        self.pathPoints = points
    }

    private func bindLiveSession() {
        tripTrackingService.currentSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.pathPoints = session?.path ?? []
            }
            .store(in: &cancellables)
    }
}
