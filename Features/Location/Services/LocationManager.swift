import Foundation
import UIKit
import CoreLocation
import Combine

/// LocationManager is the single entry point for all location and heading updates in the app.
/// Minimal, always-on pipeline:
///  - Requests Always authorization on init
///  - Arms Significant Location Change monitoring
///  - Starts continuous GPS + heading updates (re-asserts on auth changes)
///  - Emits through Combine publishers
/// On SLC cold-launch, we do not start continuous updates until the app becomes active; we only persist + optionally notify.
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Published State
    @Published private(set) var currentLocation: LocationPoint?
    @Published private(set) var lastLocation: LocationPoint?
    @Published private(set) var trueHeading: CLLocationDirection = 0
    @Published private(set) var compassHeading: CLLocationDirection = 0
    
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Core Location
    private let locationManager = CLLocationManager()
    
    // MARK: - Publishers
    private let locationSubject = CurrentValueSubject<LocationPoint?, Never>(nil)
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()
    var locationPublisher: AnyPublisher<LocationPoint, Never> {
        locationSubject.compactMap { $0 }.eraseToAnyPublisher()
    }
    var headingPublisher: AnyPublisher<CLLocationDirection, Never> {
        headingSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Persistence
    private let lastKnownStore = LastKnownLocationStore()
    
    // MARK: - Notification Throttle (persistent)
    /// Persisted key for the last user notification time (Date).
    private let lastNotificationDateKey = "LocationManager.lastNotificationDate"
    
    /// Last time we sent a user notification (persisted across launches).
    /// Read/write goes through UserDefaults to survive app termination & relaunch.
    private var lastNotificationDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: lastNotificationDateKey) as? Date
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: lastNotificationDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastNotificationDateKey)
            }
        }
    }
    
    /// Returns the elapsed time since the last notification was sent, if any.
    /// - Returns: Number of seconds since the last notification, or nil if never sent.
    func timeSinceLastNotification() -> TimeInterval? {
        guard let last = lastNotificationDate else { return nil }
        return Date().timeIntervalSince(last)
    }
    
    /// Whether we should notify the user, based on a minimum required interval.
    /// - Parameter minInterval: Minimum seconds that must elapse between notifications.
    func shouldNotifyUser(minInterval: TimeInterval) -> Bool {
        guard let elapsed = timeSinceLastNotification() else {
            return true // never notified; allowed
        }
        return elapsed >= minInterval
    }
    
    /// Call this right after you dispatch a user notification so future checks are throttled.
    func markUserNotifiedNow() {
        lastNotificationDate = Date()
    }
    
    /// Resets the remembered last notification time (e.g., user toggled a setting).
    func resetNotificationThrottle() {
        lastNotificationDate = nil
    }
    
    // (Optional usage note to future maintainers in comments):
    // When you actually send a notification (likely via `UserNotifier`), call `markUserNotifiedNow()`;
    // to gate notifications, call `shouldNotifyUser(minInterval:)` before scheduling.
    
    // MARK: - Init
    private override init() {
        super.init()
        setupLocationManager()
        requestAuthorizationAndStart()
        seedLastKnownIfAvailable()
        // Observe app becoming active to clear SLC suppression and start continuous updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
        locationManager.headingFilter = 1
        locationManager.activityType = .automotiveNavigation
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    private func requestAuthorizationAndStart() {
        // Request Always; background streaming requires it (plus Background Modes in Info.plist)
        locationManager.requestAlwaysAuthorization()
        // Arm SLC immediately (safe to call repeatedly)
        locationManager.startMonitoringSignificantLocationChanges()
        // Removed startContinuousUpdates() here to avoid starting GPS on SLC cold wakes
    }
    
    private func seedLastKnownIfAvailable() {
        if let stored = lastKnownStore.latestLocation {
            let wrapped = LocationPoint(stored)
            lastLocation = nil
            currentLocation = wrapped
            locationSubject.send(wrapped)
        }
    }
    
    // MARK: - Public API
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - Start Helpers
    private func startContinuousUpdates() {
        // Allow background streaming when Always is granted
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            // Always arm SLC; safe to repeat
            locationManager.startMonitoringSignificantLocationChanges()
            // Start continuous updates only when app is foreground/active OR
            // when this is not an SLC cold-launch suppression.
            let state = UIApplication.shared.applicationState
            if state == .active {
                startContinuousUpdates()
            } else if !suppressStreamingUntilForeground {
                // Background but not a cold SLC relaunch → allowed to start (e.g., app was already running)
                startContinuousUpdates()
            }
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        
        if suppressStreamingUntilForeground && UIApplication.shared.applicationState == .background {
            if pendingSLCLaunch {
                pendingSLCLaunch = false
                lastKnownStore.update(latest)
 
                let minInterval: TimeInterval = 2 * 60 * 60
                if shouldNotifyUser(minInterval: minInterval) {
//                    UserNotifier.shared.showMovementReminder()
                    markUserNotifiedNow()
                }
            }
            return
        }
        
        let previous = currentLocation
        let newPoint = LocationPoint(latest)
        
        if let prev = previous { lastLocation = prev } else { lastLocation = nil }
        currentLocation = newPoint
        locationSubject.send(newPoint)
        
        // Persist last known
        lastKnownStore.update(latest)
        
        // If course is valid, mirror it to trueHeading for snappier map orientation
        if latest.course >= 0 { trueHeading = latest.course; headingSubject.send(latest.course) }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Update compass and true heading from device sensors
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        compassHeading = heading
        trueHeading = heading
        headingSubject.send(heading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log("Error: \(error.localizedDescription)")
    }
    
    @objc private func onDidBecomeActive(_ notification: Notification) {
        suppressStreamingUntilForeground = false
        startContinuousUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    // MARK: - Suppression flags for SLC cold-launch
    private var suppressStreamingUntilForeground = true
    private var pendingSLCLaunch = true
}
