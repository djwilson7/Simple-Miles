import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var pathPoints: [CoordinateModel] = []
    @Published var currentLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition
    @Published var autoFollowEnabled: Bool = false
    @Published var manualRecenterRequested: Bool = false

    private let sessionStore: TripSessionStoringProtocol
    private let tripTrackingService: TripTrackingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()

    init(
        sessionStore: TripSessionStoringProtocol = TripSessionStore(),
        tripTrackingService: TripTrackingServiceProtocol = TripTrackingService.shared
    ) {
        self.sessionStore = sessionStore
        self.tripTrackingService = tripTrackingService
        self.cameraPosition = .automatic
        super.init()
        bindLiveSession()
        bindTripStatus()
        configureLocationManager()
        bindLocationToCamera()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    func recenter() {
        guard let location = currentLocation else { return }
        autoFollowEnabled = true
        withAnimation {
            self.cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 500,
                    heading: 0,
                    pitch: 0
                )
            )
        }
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            if self.currentLocation == nil {
                self.cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: latest.coordinate,
                        distance: 500,
                        heading: 0,
                        pitch: 0
                    )
                )
            }

            self.currentLocation = latest
        }
    }

    private func bindLocationToCamera() {
        $currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self, self.autoFollowEnabled else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 500,
                            heading: 0,
                            pitch: 0
                        )
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func bindTripStatus() {
        tripTrackingService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .recording {
                    self.autoFollowEnabled = true
                    self.recenter()
                }
            }
            .store(in: &cancellables)
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
