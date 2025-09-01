import Foundation
import UIKit
import CoreLocation
import Combine

final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    @Published private(set) var currentLocation: LocationPoint?
    @Published private(set) var lastLocation: LocationPoint?
    @Published private(set) var trueHeading: CLLocationDirection = 0
    @Published private(set) var compassHeading: CLLocationDirection = 0

    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    private let locationSubject = CurrentValueSubject<LocationPoint?, Never>(nil)
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()
    var locationPublisher: AnyPublisher<LocationPoint, Never> {
        locationSubject.compactMap { $0 }.eraseToAnyPublisher()
    }
    var headingPublisher: AnyPublisher<CLLocationDirection, Never> {
        headingSubject.eraseToAnyPublisher()
    }
        
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
    
    private override init() {
        super.init()
        setupLocationManager()
        requestAuthorizationAndStart()
        seedLastKnownIfAvailable()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
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
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    private func seedLastKnownIfAvailable() {
        if let stored = loadLastKnownLocation() {
            lastLocation = nil
            currentLocation = stored
            locationSubject.send(stored)
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    private func startContinuousUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startMonitoringSignificantLocationChanges()
            let state = UIApplication.shared.applicationState
            if state == .active {
                startContinuousUpdates()
            } else if !suppressStreamingUntilForeground {
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
                persistLastKnownLocation(LocationPoint(latest))
 
                let minInterval: TimeInterval = 2 * 60 * 60
                if shouldNotifyUser(minInterval: minInterval) {
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
    
    @objc private func onDidBecomeActive(_ notification: Notification) {
        suppressStreamingUntilForeground = false
        startContinuousUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private var suppressStreamingUntilForeground = true
    private var pendingSLCLaunch = true
}

// MARK: - Persistence (UserDefaults)
private extension LocationManager {
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
