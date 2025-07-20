import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var headingPublisher: AnyPublisher<CLLocationDirection, Never> {
        headingSubject.eraseToAnyPublisher()
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
        print("[Location Manager] - initialize() called")
        locationManager.requestWhenInUseAuthorization()
        print("[Location Manager] - Requested When In Use Authorization")
        locationManager.requestAlwaysAuthorization()
        print("[Location Manager] - Requested Always Authorization")
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        print("[Location Manager] - Started Location and Heading Updates")
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        print("[Location Manager] - Stopped Location and Heading Updates")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        locationSubject.send(latest)
        print("[Location Manager] - Location Update: Lat(\(latest.coordinate.latitude)), Lon(\(latest.coordinate.longitude))")

        if latest.course >= 0 {
            headingSubject.send(latest.course)
            print("[Location Manager] - Course Heading Update: \(latest.course)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingSubject.send(heading)
        print("[Location Manager] - Compass Heading Update: \(heading)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("[Location Manager] - Authorization Changed: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            print("[Location Manager] - Authorized, starting location + heading updates")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            print("[Location Manager] - Authorization not determined, requesting")
        default:
            print("[Location Manager] - Authorization denied or restricted")
        }
    }
}
