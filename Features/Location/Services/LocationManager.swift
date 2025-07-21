// LocationService.swift

import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    static let shared = LocationService()

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

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
        locationManager.headingFilter = 1
        locationManager.headingOrientation = .portrait
    }

    func initialize() {
        print("[LocationService] Requesting always authorization")
        locationManager.requestAlwaysAuthorization()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[LocationService] didUpdateLocations: \(locations)")
        guard let latest = locations.last else { return }
        locationSubject.send(latest)
        lastKnownStore.update(latest)

        if latest.course >= 0 {
            headingSubject.send(latest.course)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("[LocationService] didUpdateHeading: \(newHeading)")
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingSubject.send(heading)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("[LocationService] didChangeAuthorization: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedAlways:
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false

            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()

            if let last = lastKnownStore.latestLocation {
                locationSubject.send(last)
                print("[LocationService] Last known stored location: \(last)")
            }

            if let bootLocation = locationManager.location {
                print("[LocationService] locationManager.location at init: \(bootLocation.coordinate)")
            }

            var retryAttempts = 0
            func pollLocation() {
                guard self.locationManager.location == nil, retryAttempts < 5 else { return }

                print("[LocationService] Requesting location attempt: \(retryAttempts + 1)")
                self.locationManager.requestLocation()
                retryAttempts += 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let current = self.locationManager.location {
                        self.locationSubject.send(current)
                        print("[LocationService] Received current location: \(current)")
                        self.lastKnownStore.update(current)
                    } else {
                        pollLocation()
                    }
                }
            }
            pollLocation()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        case .notDetermined:
            break
        default:
            break
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationService] didFailWithError: \(error.localizedDescription)")
    }
}
