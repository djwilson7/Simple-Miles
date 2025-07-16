//
//  TripTrackingService.swift
//  SimpleMiles
//

import Foundation
import CoreLocation

final class TripTrackingService: NSObject, CLLocationManagerDelegate {
    static let shared = TripTrackingService(state: TripRecordingState())

    @Published private(set) var currentSession: TripSessionModel?
    let recordingState: TripRecordingState

    private let locationManager: CLLocationManager
    var analyzer: MovementAnalyzerProtocol

    private var segments: [TripSegmentModel] = []
    private var recording = false
    private var recentIdleDurations: [TimeInterval] = []

    private var lastCoordinate: CLLocationCoordinate2D?
    private var lastMovementTimestamp: Date?
    private var idleStartTime: Date?
    private var stationaryReferenceLocation: CLLocation?
    private var stationaryStartTime: Date?

    private var passiveLastLocation: CLLocation?
    private var passiveMonitorStartTime: Date?
    private var pausedLocation: CLLocation?

    var onTripSaved: (() -> Void)?

    private let stationaryDistanceThreshold: CLLocationDistance = 10
    private let stationaryThresholdDuration: TimeInterval = 15

    init(state: TripRecordingState) {
        self.recordingState = state
        self.locationManager = CLLocationManager()
        self.analyzer = MovementAnalyzer(speedThreshold: 2.5, distanceThreshold: 50)
        super.init()
        configureLocationManager()
        print("[Init] TripTrackingService initialized")
    }

    func updateAnalyzerThresholds(speed: CLLocationSpeed, distance: CLLocationDistance) {
        self.analyzer = MovementAnalyzer(speedThreshold: speed, distanceThreshold: distance)
        print("[Analyzer] Updated thresholds: speed=\(speed), distance=\(distance)")
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
    }

    func startPassiveMonitoring() {
        print("[Monitor] Passive monitoring started")
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 100
        locationManager.startUpdatingLocation()
    }

    func startRecording() {
        currentSession = TripSessionModel()
        segments = []
        recording = true
        lastCoordinate = nil
        recentIdleDurations = []
        lastMovementTimestamp = Date()
        idleStartTime = nil
        stationaryReferenceLocation = nil
        stationaryStartTime = nil

        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()

        recordingState.isRecording = true
        recordingState.session = currentSession
        recordingState.startTimer()
    }

    func stopRecording() {
        guard recording else { return }

        if var finalized = currentSession {
            finalized.segments = segments
            finalized.distance = recordingState.totalDistance
            finalized.endTime = Date()
            TripSessionStore.shared.save(finalized)
            onTripSaved?()
        }

        recording = false
        locationManager.stopUpdatingLocation()
        recordingState.stopTimer()
        recordingState.update(with: currentSession)
        recordingState.isRecording = false
        currentSession = nil
        stationaryReferenceLocation = nil
        stationaryStartTime = nil
    }

    func resumeRecording(from session: TripSessionModel) {
        segments = session.segments
        currentSession = TripSessionModel(
            id: session.id,
            startTime: session.startTime,
            endTime: nil,
            distance: session.distance,
            tripType: session.tripType,
            segments: session.segments
        )
        lastCoordinate = nil
        lastMovementTimestamp = Date()
        idleStartTime = nil
        recording = true
        locationManager.startUpdatingLocation()

        recordingState.isRecording = true
        recordingState.session = currentSession
        recordingState.startTimer()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("[Location] didUpdateLocations count: \(locations.count)")
        print("[Location] Recording? \(recording), Paused? \(recordingState.isPaused)")

        if recording {
            for location in locations {
                handleLocationSegment(location)
                analyzeMovement(location: location)
            }
        } else {
            handlePassiveTrigger(location)
        }
    }

    private func handlePassiveTrigger(_ location: CLLocation) {
        if passiveLastLocation == nil {
            passiveLastLocation = location
            passiveMonitorStartTime = Date()
            return
        }

        guard let last = passiveLastLocation, let start = passiveMonitorStartTime else { return }
        let distance = location.distance(from: last)
        let timeElapsed = Date().timeIntervalSince(start)

        print("[Monitor] Passive check: \(distance)m over \(timeElapsed)s")

        if distance > 100 && timeElapsed < 15 {
            print("[Monitor] Triggering startTrip from passive monitoring")
            TripRecorder.shared.startTrip()
        }

        passiveLastLocation = location
        passiveMonitorStartTime = Date()
    }

    private func handleLocationSegment(_ location: CLLocation) {
        guard recording else { return }

        let now = Date()
        if let last = lastCoordinate {
            let start = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let distance = location.distance(from: start)
            print("[Segment] Distance added: \(distance), Total: \(recordingState.totalDistance)")

            let segment = TripSegmentModel(
                startTime: now,
                endTime: now,
                startCoordinate: CoordinateModel(from: start.coordinate),
                endCoordinate: CoordinateModel(from: location.coordinate),
                distance: distance
            )

            segments.append(segment)
            currentSession?.segments = segments
            currentSession?.distance += distance

            DispatchQueue.main.async {
                self.recordingState.totalDistance += distance
                self.recordingState.segmentCount = self.segments.count
            }
        }

        lastCoordinate = location.coordinate
    }

    private func analyzeMovement(location: CLLocation) {
        let now = Date()
        let speed = max(location.speed, 0)

        if !recording && !recordingState.isPaused {
            if analyzer.shouldStartTrip(speed: speed, acceleration: nil) {
                TripRecorder.shared.startTrip()
                return
            }
        }

        if recordingState.isPaused {
            print("[Resume] Attempting resumeTripIfNeeded")
            let movedFar = analyzer.shouldResume(from: location, lastStoppedLocation: pausedLocation)
            let didResume = movedFar || analyzer.isMoving(speed: speed) ? TripRecorder.shared.resumeTripIfNeeded() : false
            print("[Resume] Success: \(didResume)")
        }

        if analyzer.isMoving(speed: speed) {
            lastMovementTimestamp = now
            idleStartTime = nil
            stationaryReferenceLocation = nil
            stationaryStartTime = nil
            recordingState.cancelPauseCountdown()
            return
        }

        if stationaryReferenceLocation == nil {
            stationaryReferenceLocation = location
            stationaryStartTime = now
        }

        if let ref = stationaryReferenceLocation {
            let distance = location.distance(from: ref)
            if distance > stationaryDistanceThreshold {
                stationaryReferenceLocation = location
                stationaryStartTime = now
                return
            }

            if let since = stationaryStartTime,
               now.timeIntervalSince(since) >= stationaryThresholdDuration {
                if recording && !recordingState.isPaused {
                    print("[Pause] Recording paused — saving last known location")
                    self.pausedLocation = location
                    TripRecorder.shared.pauseTrip()
                    recordingState.startPauseCountdown()
                    self.startPassiveMonitoring()
                }
            }
        }
    }

    func clearAllTrips() {
        TripSessionStore.shared.clearAll()
        recordingState.reset()
        print("[Storage] All trips cleared and recording state reset")
    }
}
