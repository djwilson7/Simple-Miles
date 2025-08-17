import Foundation
import UIKit
import CoreLocation
import Combine

/// LocationManager is the single entry point for all location and heading updates in the app.
/// It supports:
/// - High-accuracy GPS streaming for active trip recording.
/// - Significant Location Change monitoring to wake the app in the background when movement is detected.
/// - Dynamic heading source switching (course vs. compass) based on speed.
/// - Persistent last-known location storage.
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Public Published State
    
    /// Most recent known location from GPS, wrapped in LocationPoint.
    @Published private(set) var currentLocation: LocationPoint?
    /// The location received before the current one, wrapped in LocationPoint.
    @Published private(set) var lastLocation: LocationPoint?
    /// Calculated speed from the most recent updates (m/s).
    @Published private(set) var speed: CLLocationSpeed = 0
    /// The current heading in degrees (true north if available).
    @Published private(set) var trueHeading: CLLocationDirection = 0
    /// The current compass heading in degrees (magnetic north fallback).
    @Published private(set) var compassHeading: CLLocationDirection = 0
    
    // MARK: - Singleton
    
    static let shared = LocationManager()
    
    // MARK: - Private Core Location
    
    private let locationManager = CLLocationManager()
    /// Emits LocationPoint objects instead of CLLocation directly.
    private let locationSubject = CurrentValueSubject<LocationPoint?, Never>(nil)
    private let headingSubject = PassthroughSubject<CLLocationDirection, Never>()
    
    private let lastKnownStore = LastKnownLocationStore()
    
    // MARK: - Heading Preference State
    
    private var lowSpeedTimer: Timer?
    private let lowSpeedThreshold: CLLocationSpeed = 2.24 // 5 mph
    private let revertDelay: TimeInterval = 45            // seconds
    private var preferCourseHeading: Bool = false
    private var lastCLHeading: CLLocationDirection = 0
    private var orientationOffset: CLLocationDirection = 0.0
    
    // MARK: - Significant Change State
    
    private var significantChangeActive: Bool = false
    private let minNotificationInterval: TimeInterval = 2 * 60 * 60 // 2 hours
    private var lastNotificationDate: Date?
    
    // MARK: - Update Mode State
    private var isGPSActive = false
    private var isHeadingActive = false

    // MARK: - First Fix State
    private var hasReceivedFirstFix = false

    // MARK: - Public Publishers
    
    var locationPublisher: AnyPublisher<LocationPoint, Never> {
        locationSubject.compactMap { $0 }.eraseToAnyPublisher()
    }
    
    var headingPublisher: AnyPublisher<CLLocationDirection, Never> {
        headingSubject.eraseToAnyPublisher()
    }
    
    /// Last saved location from persistent storage, wrapped in LocationPoint.
    var lastKnownLocation: LocationPoint? {
        if let loc = lastKnownStore.latestLocation {
            return LocationPoint(loc)
        }
        return nil
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
        locationManager.headingFilter = 1
        locationManager.headingOrientation = .portrait
        locationManager.activityType = .automotiveNavigation
        locationManager.showsBackgroundLocationIndicator = false
        locationManager.requestAlwaysAuthorization()
        
        if let stored = lastKnownStore.latestLocation {
            let wrapped = LocationPoint(stored)
            lastLocation = nil
            currentLocation = wrapped
            hasReceivedFirstFix = true
            locationSubject.send(wrapped)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientationOffset), name: UIDevice.orientationDidChangeNotification, object: nil)
        updateOrientationOffset()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    // MARK: - Orientation Handling
    @objc private func updateOrientationOffset() {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            orientationOffset = 90
        case .portraitUpsideDown:
            orientationOffset = 180
        case .landscapeRight:
            orientationOffset = 270
        default:
            orientationOffset = 0
        }
    }
    
    // MARK: - Public API
    
    /// Starts monitoring significant location changes for background movement detection.
    /// Will wake the app and trigger `didUpdateLocations` even if terminated.
    func startSignificantChangeMonitoring() {
        significantChangeActive = true
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    /// Stops monitoring significant location changes.
    func stopSignificantChangeMonitoring() {
        significantChangeActive = false
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    /// Stops active high-accuracy GPS and heading updates.
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isGPSActive = false
        isHeadingActive = false
    }
    
    // MARK: - Continuous Updates Helpers
    private func startContinuousUpdatesIfNeeded() {
        if !isGPSActive {
            locationManager.startUpdatingLocation()
            isGPSActive = true
        }
        if !isHeadingActive {
            locationManager.startUpdatingHeading()
            isHeadingActive = true
        }
    }

    private func ensureBackgroundFlagsIfAllowed() {
        guard locationManager.authorizationStatus == .authorizedAlways, isGPSActive else { return }
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - App Lifecycle Hooks
    @objc private func appDidEnterBackground() {
        ensureBackgroundFlagsIfAllowed()
    }

    @objc private func appWillEnterForeground() {
        ensureBackgroundFlagsIfAllowed()
        startContinuousUpdatesIfNeeded()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            ensureBackgroundFlagsIfAllowed()
            if let last = lastKnownStore.latestLocation {
                let wrapped = LocationPoint(last)
                currentLocation = wrapped
                hasReceivedFirstFix = true
                let s = wrapped.speed
                speed = (s >= 0) ? s : 0
                locationSubject.send(wrapped)
            }
            if UIApplication.shared.applicationState != .background {
                startContinuousUpdatesIfNeeded()
            }
        case .authorizedWhenInUse:
            if UIApplication.shared.applicationState != .background {
                startContinuousUpdatesIfNeeded()
            }
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        
        let appState = UIApplication.shared.applicationState
        
        // --- Significant Change Cold-Wake Escalation ---
        if appState == .background && significantChangeActive && !isGPSActive {
            // Do NOT escalate to continuous GPS. Only notify the user.
            let now = Date()
            if lastNotificationDate == nil || now.timeIntervalSince(lastNotificationDate!) > minNotificationInterval {
                lastNotificationDate = now
                UserNotifier.shared.showMovementReminder()
            }
        }
        
        let previous = currentLocation
        let newPoint = LocationPoint(latest)

        if hasReceivedFirstFix, let prev = previous {
            lastLocation = prev
        } else {
            // First valid fix in this app session (or after cold start with no persisted point)
            lastLocation = nil
            hasReceivedFirstFix = true
        }

        currentLocation = newPoint
        locationSubject.send(newPoint)
        let s = newPoint.speed
        speed = (s >= 0) ? s : 0
        
        lastKnownStore.update(latest)
        evaluateHeadingPreference(for: latest)
    }
    
  
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading + orientationOffset : newHeading.magneticHeading + orientationOffset
        lastCLHeading = heading
        compassHeading = heading
        
        if !preferCourseHeading {
            trueHeading = heading
            headingSubject.send(heading)
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        // iOS thinks we are stationary; we prefer continuous updates. Reassert.
        ensureBackgroundFlagsIfAllowed()
        startContinuousUpdatesIfNeeded()
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        // Resume bookkeeping.
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
    }
    
    // MARK: - Heading Source Logic
    
    /// Chooses between course heading and compass heading based on speed, with a delay before switching back to compass.
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
    
    /// Sends a course heading update if available; falls back to compass heading otherwise.
    private func emitCourseHeadingIfValid(_ location: CLLocation) {
        if location.course >= 0 {
            trueHeading = location.course
            headingSubject.send(location.course)
        } else {
            print("[LocationManager] Invalid course; falling back to compass if needed")
        }
    }
    
}
