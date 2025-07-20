// TripTrackingService.swift
// SimpleMiles

import Foundation
import CoreLocation
import Combine

final class TripTrackingService: NSObject, TripTrackingServiceProtocol {
    static let shared = TripTrackingService()

    @Published private(set) var currentSession: TripSessionModel?
    var currentSessionPublisher: Published<TripSessionModel?>.Publisher { $currentSession }

    @Published private(set) var status: TripRecordingStatus = .idle
    @Published var currentHeading: CLLocationDirection = 0

    var recordingState: any TripRecordingStateProtocol
    var onTripSaved: (() -> Void)?
    var statusPublisher: Published<TripRecordingStatus>.Publisher { $status }

    private var cancellables = Set<AnyCancellable>()
    private var pathRecorder = TripPathRecorder()
    private var hasStartedPassiveMonitoring = false

    private let lifecycleManager: TripLifecycleManagingProtocol
    private let persistenceManager: TripPersistenceManagingProtocol
    private let movementMonitor: MovementMonitoringProtocol
    private let locationService: LocationServiceProtocol

    init(
        lifecycleManager: TripLifecycleManagingProtocol = TripLifecycleManager(),
        persistenceManager: TripPersistenceManagingProtocol = TripPersistenceManager(),
        movementMonitor: MovementMonitoringProtocol = MovementMonitor(analyzer: MovementAnalyzer()),
        locationService: LocationServiceProtocol = LocationService.shared
    ) {
        self.recordingState = TripRecordingState() as any TripRecordingStateProtocol
        self.lifecycleManager = lifecycleManager
        self.persistenceManager = persistenceManager
        self.movementMonitor = movementMonitor
        self.locationService = locationService
        super.init()
        bindSession()
        bindLocationUpdates()
        wireMovementCallbacks()
    }

    private func bindSession() {
        $currentSession
            .sink { [weak self] session in
                self?.recordingState.update(with: session)
            }
            .store(in: &cancellables)
    }

    private func bindLocationUpdates() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (location: CLLocation) in
                guard let self = self else { return }

                if !self.recordingState.isRecording && !self.hasStartedPassiveMonitoring {
                    self.hasStartedPassiveMonitoring = true
                    self.startPassiveMonitoring()
                }

                self.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        locationService.headingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentHeading)
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        movementMonitor.analyze(location: location)

        guard recordingState.isRecording, lifecycleManager.currentSession != nil else { return }

        pathRecorder.append(location.coordinate)

        guard let active = lifecycleManager.currentSession else { return }
        var updated = active
        updated.path = pathRecorder.coordinates
        updated.distance = computeTotalDistance(for: updated.path)
        currentSession = updated
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
        movementMonitor.startPassiveMonitoring()
    }

    func updateAnalyzerThresholds(speed: Double, distance: Double) {
        movementMonitor.updateThresholds(speed: speed, distance: distance)
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

    #if DEBUG
    init(
        lifecycleManager: TripLifecycleManagingProtocol,
        pathRecorder: TripPathRecorder,
        persistenceManager: TripPersistenceManagingProtocol,
        movementMonitor: MovementMonitoringProtocol,
        recordingState: any TripRecordingStateProtocol,
        locationService: LocationServiceProtocol = LocationService.shared
    ) {
        self.lifecycleManager = lifecycleManager
        self.pathRecorder = pathRecorder
        self.persistenceManager = persistenceManager
        self.movementMonitor = movementMonitor
        self.recordingState = recordingState
        self.locationService = locationService
        super.init()
        bindSession()
        bindLocationUpdates()
        wireMovementCallbacks()
    }
    #endif
}
