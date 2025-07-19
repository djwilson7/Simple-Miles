//
//  MapViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine
import CoreLocation

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var pathPoints: [CoordinateModel] = []
    @Published var currentLocation: CLLocation?

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
        super.init()
        bindLiveSession()
        configureLocationManager()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = latest
        }
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
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
