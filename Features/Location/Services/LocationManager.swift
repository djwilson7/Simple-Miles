import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, CLLocationManagerDelegate {
    // MARK: - Public State
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var speed: CLLocationSpeed = 0
    @Published private(set) var trueHeading: CLLocationDirection = 0
    @Published private(set) var compassHeading: CLLocationDirection = 0

    // MARK: - Private State
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()
    private let lastKnownStore = LastKnownLocationStore()

    private var lowSpeedTimer: Timer?
    private let lowSpeedThreshold: CLLocationSpeed = 2.24 // 5 mph
    private let revertDelay: TimeInterval = 45            // 45 seconds
    private var preferCourseHeading: Bool = false
    private var lastCLHeading: CLLocationDirection = 0

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.compactMap { $0 }.eraseToAnyPublisher()
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
        locationManager.requestAlwaysAuthorization()

        if let stored = lastKnownStore.latestLocation {
            lastLocation = stored
            currentLocation = lastLocation
            locationSubject.send(lastLocation)
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            if let last = lastKnownStore.latestLocation {
                locationSubject.send(last)
            }
            pollLocation()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        lastLocation = currentLocation
        currentLocation = latest
        locationSubject.send(latest)

        if let previous = lastLocation {
            let deltaDistance = latest.distance(from: previous)
            let deltaTime = latest.timestamp.timeIntervalSince(previous.timestamp)
            if deltaTime > 0 {
                speed = deltaDistance / deltaTime
            }
        }

        lastKnownStore.update(latest)
        evaluateHeadingPreference(for: latest)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        lastCLHeading = heading
        compassHeading = heading

        if !preferCourseHeading {
            trueHeading = heading
            headingSubject.send(heading)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
    }

    // MARK: - Heading Source Logic

    private func evaluateHeadingPreference(for location: CLLocation) {
        let isFast = location.speed >= lowSpeedThreshold

        if isFast {
            if !preferCourseHeading {
                preferCourseHeading = true
            }
            lowSpeedTimer?.invalidate()
            emitCourseHeadingIfValid(location)
        } else {
            if lowSpeedTimer == nil {
                lowSpeedTimer = Timer.scheduledTimer(withTimeInterval: revertDelay, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.preferCourseHeading = false
                    self.lowSpeedTimer = nil
                    self.trueHeading = self.lastCLHeading
                    self.headingSubject.send(self.lastCLHeading)
                }
            }
        }
    }

    private func emitCourseHeadingIfValid(_ location: CLLocation) {
        if location.course >= 0 {
            trueHeading = location.course
            headingSubject.send(location.course)
        } else {
            print("[LocationManager] Invalid course; falling back to compass if needed")
        }
    }

    // MARK: - Helpers

    private func pollLocation() {
        var retryAttempts = 0
        func attempt() {
            guard self.locationManager.location == nil, retryAttempts < 5 else { return }

            self.locationManager.requestLocation()
            retryAttempts += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let current = self.locationManager.location {
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
