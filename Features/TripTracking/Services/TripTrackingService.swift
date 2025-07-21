// TripTrackingService.swift

import Foundation
import CoreLocation
import Combine

final class TripTrackingService: NSObject, TripTrackingServiceProtocol {
    static let shared = TripTrackingService()

    @Published private(set) var currentSession: TripSessionModel?
    var currentSessionPublisher: Published<TripSessionModel?>.Publisher { $currentSession }

    @Published private(set) var status: TripRecordingStatus = .idle
    @Published private(set) var currentHeading: CLLocationDirection = 0

    private(set) var recordingState: any TripRecordingStateProtocol
    var onTripSaved: (() -> Void)?
    var statusPublisher: Published<TripRecordingStatus>.Publisher { $status }

    private var cancellables = Set<AnyCancellable>()
    private let pathRecorder = TripPathRecorder()
    private var hasStartedPassiveMonitoring = false

    private let lifecycleManager: TripLifecycleManagingProtocol
    private let persistenceManager: TripPersistenceManagingProtocol
    private let movementMonitor: MovementMonitoringProtocol
    private let locationService: LocationServiceProtocol
    private let motionService: MotionService

    init(
        lifecycleManager: TripLifecycleManagingProtocol = TripLifecycleManager(),
        persistenceManager: TripPersistenceManagingProtocol = TripPersistenceManager(),
        movementMonitor: MovementMonitoringProtocol = MovementMonitor(analyzer: MovementAnalyzer()),
        locationService: LocationServiceProtocol = LocationService.shared,
        motionService: MotionService = MotionService.shared
    ) {
        self.lifecycleManager = lifecycleManager
        self.persistenceManager = persistenceManager
        self.movementMonitor = movementMonitor
        self.locationService = locationService
        self.motionService = motionService
        self.recordingState = TripRecordingState() as any TripRecordingStateProtocol
        super.init()
        bindSession()
        bindLocationUpdates()
        wireMovementCallbacks()
        // Observe remainingPauseTime and auto-stop when it runs out while paused
        recordingState.publisherValues.remainingPauseTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                guard let self else { return }
                if self.status == .paused && remaining <= 0 {
                    self.stopRecording()
                }
            }
            .store(in: &cancellables)
    }

    private func bindSession() {
        $currentSession
            .sink(receiveValue: { [weak self] session in
                self?.recordingState.update(with: session)
            })
            .store(in: &cancellables)
    }

    private func bindLocationUpdates() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] location in
                guard let self = self else { return }

                if !recordingState.isRecording && !hasStartedPassiveMonitoring {
                    hasStartedPassiveMonitoring = true
                    startPassiveMonitoring()
                }

                movementMonitor.updateLastLocation(location)

                let coord = CoordinateModel(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    state: self.recordingState.isRecording ? .active : .paused
                )

                pathRecorder.append(coord)

                guard self.recordingState.isRecording,
                      var session = self.lifecycleManager.currentSession else { return }

                session.path = self.pathRecorder.coordinates
                session.distance = self.computeTotalDistance(for: session.path)
                self.currentSession = session
            })
            .store(in: &cancellables)

        locationService.headingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentHeading)
    }

    private func wireMovementCallbacks() {
        movementMonitor.onShouldStartTrip = { [weak self] in self?.startRecording() }
        movementMonitor.onShouldPauseTrip = { [weak self] in self?.pauseTracking() }
        movementMonitor.onShouldResumeTrip = { [weak self] in self?.resumeTracking() }
        movementMonitor.onShouldStopTrip = { [weak self] in self?.stopRecording() }
    }

    func startRecording() {
        guard !recordingState.isRecording else { return }
        lifecycleManager.startSession()
        currentSession = lifecycleManager.currentSession
        pathRecorder.reset()
        recordingState.setRecording(true)
        status = .recording
        NotificationCenter.default.post(name: .tripDidStart, object: nil)
    }

    func stopRecording() {
        lifecycleManager.stopSession()
        guard var trip = lifecycleManager.currentSession else { return }

        recordingState.cancelPauseCountdown()
        recordingState.setRecording(false)
        status = .idle

        trip.path = pathRecorder.coordinates
        trip.distance = computeTotalDistance(for: trip.path)
        currentSession = nil

        persistenceManager.save(trip)
        onTripSaved?()
        hasStartedPassiveMonitoring = false
        startPassiveMonitoring()
        NotificationCenter.default.post(name: .tripDidEnd, object: nil)
    }

    func pauseTracking() {
        recordingState.startPauseCountdown(duration: 600)
        recordingState.setRecording(false)
        status = .paused
        NotificationCenter.default.post(name: .tripDidPause, object: nil)
    }

    private func resumeTracking() {
        recordingState.cancelPauseCountdown()
        recordingState.setRecording(true)
        status = .recording
        NotificationCenter.default.post(name: .tripDidResume, object: nil)
    }

    func startPassiveMonitoring() {
        motionService.startUpdates()
        movementMonitor.startPassiveMonitoring()
    }

    private func computeTotalDistance(for path: [CoordinateModel]) -> Double {
        guard path.count > 1 else { return 0 }
        return zip(path.dropLast(), path.dropFirst()).reduce(0) { total, pair in
            let start = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
            let end = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
            return total + start.distance(from: end)
        }
    }

    func resumeRecording(from session: TripSessionModel) {
        currentSession = session
        recordingState.setRecording(true)
        status = .recording
    }

    func clearAllTrips() {
        persistenceManager.clearAllTrips()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didClearTripData, object: nil)
        }
    }
}
