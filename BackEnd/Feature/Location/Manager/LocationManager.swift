import Foundation
#if os(iOS)
import UIKit
#endif
import CoreLocation
import Combine

/// Coordinates Core Location services and exposes location and heading updates.
/// Acts as a single source of truth for current/last location and heading streams.
final class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Singleton
    static let shared = LocationManager()

    // MARK: - Dependencies
    private let locationManager = CLLocationManager()

    // MARK: - Published State (Outputs)
    @Published private(set) var currentLocation: LocationPoint?
    @Published private(set) var lastLocation: LocationPoint?
    @Published private(set) var trueHeading: CLLocationDirection = 0
    @Published private(set) var compassHeading: CLLocationDirection = 0

    // MARK: - Streams (Combine)
    private let locationSubject = CurrentValueSubject<LocationPoint?, Never>(nil)
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()
    var locationPublisher: AnyPublisher<LocationPoint, Never> {
        locationSubject.compactMap { $0 }.eraseToAnyPublisher()
    }
    var headingPublisher: AnyPublisher<CLLocationDirection, Never> {
        headingSubject.eraseToAnyPublisher()
    }

    // MARK: - Private State
    private var suppressStreamingUntilForeground = true
    private var pendingSLCLaunch = true

    private var lastNotificationDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: UserDefaultKeys.lastNotificationDate.rawValue) as? Date
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: UserDefaultKeys.lastNotificationDate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultKeys.lastNotificationDate.rawValue)
            }
        }
    }

    // MARK: - Init
    private override init() {
        super.init()
        setupLocationManager()
        requestAuthorizationAndStart()
        seedLastKnownIfAvailable()

        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
    }

    // MARK: - Public API (Intents)
    func timeSinceLastNotification() -> TimeInterval? {
        guard let last = lastNotificationDate else { return nil }
        return Date().timeIntervalSince(last)
    }

    func shouldNotifyUser(minInterval: TimeInterval) -> Bool {
        guard let elapsed = timeSinceLastNotification() else {
            return true
        }
        return elapsed >= minInterval
    }

    func markUserNotifiedNow() {
        lastNotificationDate = Date()
    }

    func resetNotificationThrottle() {
        lastNotificationDate = nil
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        #if os(iOS)
        locationManager.stopUpdatingHeading()
        #endif
    }

    // MARK: - Bindings (CLLocationManagerDelegate)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startMonitoringSignificantLocationChanges()
            #if os(iOS)
            let state = UIApplication.shared.applicationState
            if state == .active {
                startContinuousUpdates()
            } else if !suppressStreamingUntilForeground {
                startContinuousUpdates()
            }
            #else
            startContinuousUpdates()
            #endif
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        #if os(iOS)
        if suppressStreamingUntilForeground && UIApplication.shared.applicationState == .background {
            if pendingSLCLaunch {
                pendingSLCLaunch = false
                persistLastKnownLocation(LocationPoint(latest))

                let minInterval: TimeInterval = 2 * 60 * 60
                if shouldNotifyUser(minInterval: minInterval) {
                    markUserNotifiedNow()
                }
            }
            return
        }
        #endif

        let previous = currentLocation
        let newPoint = LocationPoint(latest)

        if let prev = previous { lastLocation = prev } else { lastLocation = nil }
        currentLocation = newPoint
        locationSubject.send(newPoint)

        persistLastKnownLocation(newPoint)

        if latest.course >= 0 { trueHeading = latest.course; headingSubject.send(latest.course) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        compassHeading = heading
        trueHeading = heading
        headingSubject.send(heading)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log("Error: \(error.localizedDescription)")
    }

    // MARK: - Private Helpers
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
        locationManager.headingFilter = 1
        locationManager.activityType = .automotiveNavigation
        #if os(iOS)
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.allowsBackgroundLocationUpdates = true
        #endif
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func requestAuthorizationAndStart() {
        locationManager.requestAlwaysAuthorization()
        #if os(iOS)
        locationManager.startMonitoringSignificantLocationChanges()
        #endif
    }

    func seedLastKnownIfAvailable() {
        if let stored = loadLastKnownLocation() {
            lastLocation = nil
            currentLocation = stored
            locationSubject.send(stored)
        }
    }

    func startContinuousUpdates() {
        locationManager.startUpdatingLocation()
        #if os(iOS)
        locationManager.startUpdatingHeading()
        #endif
    }

    #if os(iOS)
    @objc private func onDidBecomeActive(_ notification: Notification) {
        suppressStreamingUntilForeground = false
        startContinuousUpdates()
    }
    #endif

    func reset() {
        currentLocation = nil
        lastLocation = nil
        trueHeading = 0
        compassHeading = 0
        suppressStreamingUntilForeground = false // Ensure streaming works in tests
        resetNotificationThrottle()
        locationSubject.send(nil)
    }

    // MARK: - Lifecycle
    deinit {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        #endif
    }
}

// MARK: - Persistence (UserDefaults)
extension LocationManager {
    func persistLastKnownLocation(_ point: LocationPoint) {
        do {
            let data = try JSONEncoder().encode(point)
            UserDefaults.standard.set(data, forKey: UserDefaultKeys.lastKnownLocation.rawValue)
        } catch {
            Log("Failed to encode last known location: \(error.localizedDescription)")
        }
    }

    func loadLastKnownLocation() -> LocationPoint? {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultKeys.lastKnownLocation.rawValue) else {
            return nil
        }
        do {
            let point = try JSONDecoder().decode(LocationPoint.self, from: data)
            return point
        } catch {
            Log("Failed to decode last known location: \(error.localizedDescription)")
            return nil
        }
    }
}
