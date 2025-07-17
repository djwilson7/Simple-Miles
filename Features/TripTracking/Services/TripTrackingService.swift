import Foundation
import CoreLocation
import Combine

final class TripTrackingService: NSObject, CLLocationManagerDelegate, TripTrackingServiceProtocol {
    static let shared = TripTrackingService()

    @Published private(set) var currentSession: TripSessionModel?
    var currentSessionPublisher: Published<TripSessionModel?>.Publisher { $currentSession }

    var recordingState: any TripRecordingStateProtocol
    var onTripSaved: (() -> Void)?

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var pathRecorder = TripPathRecorder()

    private let lifecycleManager: TripLifecycleManagingProtocol
    private let persistenceManager: TripPersistenceManagingProtocol
    private let movementMonitor: MovementMonitoringProtocol

    init(
        lifecycleManager: TripLifecycleManagingProtocol = TripLifecycleManager(),
        persistenceManager: TripPersistenceManagingProtocol = TripPersistenceManager(),
        movementMonitor: MovementMonitoringProtocol = MovementMonitor(analyzer: MovementAnalyzer())
    ) {
        self.recordingState = TripRecordingState() as any TripRecordingStateProtocol
        self.lifecycleManager = lifecycleManager
        self.persistenceManager = persistenceManager
        self.movementMonitor = movementMonitor
        super.init()
        bindSession()
        configureLocationManager()
        wireMovementCallbacks()
    }

    private func bindSession() {
        print("[TripTrackingService] bindSession triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        $currentSession
            .sink { [weak self] session in
                self?.recordingState.update(with: session)
            }
            .store(in: &cancellables)
    }

    private func configureLocationManager() {
        print("[TripTrackingService] configureLocationManager triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.activityType = .automotiveNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
    }

    private func wireMovementCallbacks() {
        print("[TripTrackingService] wireMovementCallbacks triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.

        movementMonitor.onShouldStartTrip = { [weak self] in
            print("[TripTrackingService] onShouldStartTrip triggered")
            self?.startRecording()
        }

        movementMonitor.onShouldPauseTrip = { [weak self] in
            print("[TripTrackingService] onShouldPauseTrip triggered")
            self?.recordingState.startPauseCountdown(duration: 600)
            print("[TripTrackingService] isPaused after trigger: \(self?.recordingState.isPaused ?? false)")
        }

        movementMonitor.onShouldResumeTrip = { [weak self] in
            print("[TripTrackingService] onShouldResumeTrip triggered")
            self?.recordingState.cancelPauseCountdown()
            print("[TripTrackingService] isPaused after cancel: \(self?.recordingState.isPaused ?? false)")
        }
    }


    func startRecording() {
        guard !recordingState.isRecording else {
            print("[TripTrackingService] startRecording ignored – already recording") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }

        print("[TripTrackingService] startRecording triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        lifecycleManager.startSession()
        currentSession = lifecycleManager.currentSession
        pathRecorder.reset()
        locationManager.startUpdatingLocation()
    }

    func stopRecording() {
        print("[TripTrackingService] stopRecording triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        lifecycleManager.stopSession()
        guard var trip = lifecycleManager.currentSession else {
            print("[TripTrackingService] stopRecording aborted – no active session") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }

        trip.path = pathRecorder.coordinates
        trip.distance = computeTotalDistance(for: trip.path)
        currentSession = nil
        locationManager.stopUpdatingLocation()
        persistenceManager.save(trip)
        onTripSaved?()
    }

    func startPassiveMonitoring() {
        print("[TripTrackingService] startPassiveMonitoring triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        movementMonitor.startPassiveMonitoring()
        locationManager.startUpdatingLocation()
    }

    func updateAnalyzerThresholds(speed: Double, distance: Double) {
        print("[TripTrackingService] updateAnalyzerThresholds triggered with speed: \(speed), distance: \(distance)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        movementMonitor.updateThresholds(speed: speed, distance: distance)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("[TripTrackingService] no valid location received") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }

        movementMonitor.analyze(location: location)

        guard currentSession != nil else {
            print("[TripTrackingService] location update ignored – no active session") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }

        if pathRecorder.coordinates.isEmpty {
            print("[TripTrackingService] trip started at: \(location.coordinate)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        }

        pathRecorder.append(location.coordinate)
        
        if var session = currentSession {
            session.path = pathRecorder.coordinates
            session.distance = computeTotalDistance(for: session.path)
            currentSession = session
        }
    }

    private func computeTotalDistance(for path: [CoordinateModel]) -> Double {
        guard path.count > 1 else { return 0 }
        var total: Double = 0
        for i in 1..<path.count {
            let prev = CLLocation(latitude: path[i-1].latitude, longitude: path[i-1].longitude)
            let next = CLLocation(latitude: path[i].latitude, longitude: path[i].longitude)
            total += prev.distance(from: next)
        }
        return total
    }

    func resumeRecording(from session: TripSessionModel) {
        print("[TripTrackingService] resumeRecording triggered")
        currentSession = session
    }
    
    func clearAllTrips() {
        print("[TripTrackingService] clearAllTrips triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        persistenceManager.clearAllTrips()
    }

}
