// LocationManager.swift

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, CLLocationManagerDelegate {
    // MARK: - Properties

    @Published private(set) var currentLocation: CLLocation?            //current location
    @Published private(set) var lastLocation: CLLocation?               //current location - 1
    @Published private(set) var travelHeading: CLLocationDirection = 0  //bearing between last and current
    @Published private(set) var speed: CLLocationSpeed = 0              //speed between last and current
    @Published private(set) var trueHeading: CLLocationDirection = 0    //device heading from current

    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()
    private let lastKnownStore = LastKnownLocationStore()

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var headingPublisher: AnyPublisher<CLLocationDirection, Never> {
        headingSubject.eraseToAnyPublisher()
    }

    var lastKnownLocation: CLLocation? {
        lastKnownStore.latestLocation
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
        locationManager.headingFilter = 1
        locationManager.headingOrientation = .portrait
    }

    // MARK: - Public API

    func initialize() {
        // print("[LocationManager] (initialize) - Initializing location manager and loading last known location")
        locationManager.requestAlwaysAuthorization()
        if let stored = lastKnownStore.latestLocation {
            lastLocation = stored
            currentLocation = lastLocation
            locationSubject.send(lastLocation)
        }
    }

    func stopTracking() {
        // print("[LocationManager] (stopTracking) - Stopping location and heading updates")
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("[LocationManager] (locationManagerDidChangeAuthorization) - Authorization status changed: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("[LocationManager] (locationManagerDidChangeAuthorization) - Authorized Always, starting location and heading updates")
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false

            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()

            if let last = lastKnownStore.latestLocation {
                locationSubject.send(last)
            }

            if let bootLocation = locationManager.location {
                 print("[LocationManager] locationManager.location at init: \(bootLocation.coordinate)")
            }

            pollLocation()
        case .authorizedWhenInUse:
            print("[LocationManager] (locationManagerDidChangeAuthorization) - Authorized When In Use, starting location and heading updates")
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        case .notDetermined:
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        print("[LocationManager] (didUpdateLocations) - Received new location: \(latest.coordinate)")
        lastLocation = currentLocation
        currentLocation = latest
        locationSubject.send(latest)

        if let previous = lastLocation {
            print("[LocationManager] (didUpdateLocations) - Previous location: \(previous.coordinate)")
            let deltaDistance = latest.distance(from: previous)
            let deltaTime = latest.timestamp.timeIntervalSince(previous.timestamp)
            if deltaTime > 0 {
                speed = deltaDistance / deltaTime
            }
            print("[LocationManager] (didUpdateLocations) - Calculated speed: \(speed) m/s")

            travelHeading = previous.coordinate.bearing(to: latest.coordinate)
            print("[LocationManager] (didUpdateLocations) - Calculated travel heading: \(travelHeading)°")
        }

        if latest.course >= 0 {
            trueHeading = latest.course
            headingSubject.send(latest.course)
        }

        lastKnownStore.update(latest)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        //print("[LocationManager] (didUpdateHeading) - Received heading update: \(heading)")
        self.trueHeading = heading
        headingSubject.send(heading)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print("[LocationManager] (didFailWithError) - Error occurred: \(error.localizedDescription)")
    }

    // MARK: - Helpers

    private func pollLocation() {
        var retryAttempts = 0
        func attempt() {
            print("[LocationManager] (pollLocation) - Attempting to request location, try: \(retryAttempts + 1)")
            guard self.locationManager.location == nil, retryAttempts < 5 else { return }

            self.locationManager.requestLocation()
            retryAttempts += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let current = self.locationManager.location {
                    // print("[LocationManager] (pollLocation) - Successfully received location on retry: \(retryAttempts)")
                    self.locationSubject.send(current)
                    self.lastKnownStore.update(current)
                } else {
                    attempt()
                }
            }
        }
        attempt()
    }
}

private extension CLLocationCoordinate2D {
    func bearing(to destination: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = self.latitude * .pi / 180
        let lon1 = self.longitude * .pi / 180
        let lat2 = destination.latitude * .pi / 180
        let lon2 = destination.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        return radiansBearing * 180 / .pi
    }
}
