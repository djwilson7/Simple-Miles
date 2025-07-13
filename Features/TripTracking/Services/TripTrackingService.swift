import Foundation
import CoreLocation
import Combine

final class TripTrackingService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var currentSession: TripSession?
    
    private var locationManager: CLLocationManager
    private var lastCoordinate: CLLocation?
    private var segments: [TripSegment] = []

    private var recentIdleDurations: [TimeInterval] = []
    private var lastMovementTimestamp: Date?
    
    private var recording = false
    
    #if DEBUG
    var isRecording: Bool {
        return recording
    }
    #endif
    
    private var cancellables = Set<AnyCancellable>()
    
    private let analyzer: MovementAnalyzing

    // MARK: - Init with Dependency Injection
    init(analyzer: MovementAnalyzing = MovementAnalyzer()) {
        self.analyzer = analyzer
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation

        #if !DEBUG
        locationManager.allowsBackgroundLocationUpdates = true
        #endif

        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startRecording() {
        segments.removeAll()
        currentSession = TripSession(startTime: Date(), segments: [])
        lastCoordinate = nil
        lastMovementTimestamp = Date()
        recording = true
        locationManager.startUpdatingLocation()
    }

    func stopRecording() {
        guard recording, var session = currentSession else { return }
        session.endTime = Date()
        session.segments = segments
        currentSession = session
        recording = false
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }

        analyzeMovement(location: location)

        if recording {
            handleLocationSegment(location)
        }
    }

    private func handleLocationSegment(_ location: CLLocation) {
        guard let last = lastCoordinate else {
            lastCoordinate = location
            return
        }

        let segment = TripSegment(
            id: UUID(),
            startTime: last.timestamp,
            endTime: location.timestamp,
            startCoordinate: Coordinate(from: last.coordinate),
            endCoordinate: Coordinate(from: location.coordinate),
            distance: location.distance(from: last)
        )

        segments.append(segment)
        lastCoordinate = location
        currentSession?.segments = segments
    }

    private func analyzeMovement(location: CLLocation) {
        let now = Date()
        let speed = location.speed > 0 ? location.speed : 0

        if analyzer.isMoving(speed: speed) {
            lastMovementTimestamp = now
        }

        if let lastMove = lastMovementTimestamp {
            let idleTime = now.timeIntervalSince(lastMove)
            recentIdleDurations.append(idleTime)
            if recentIdleDurations.count > 10 {
                recentIdleDurations.removeFirst()
            }
        }

        if !recording, analyzer.shouldStartTrip(speed: speed, acceleration: nil) {
            startRecording()
        }

        if recording, analyzer.shouldStopTrip(recentIdleDurations: recentIdleDurations, speed: speed, acceleration: nil) {
            stopRecording()
        }
    }
}

#if DEBUG
extension TripTrackingService {
    func simulate(_ locations: [CLLocation]) {
        for location in locations {
            self.locationManager(self.locationManager, didUpdateLocations: [location])
        }
    }
}
#endif
