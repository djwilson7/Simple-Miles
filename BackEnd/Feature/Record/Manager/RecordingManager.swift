import Foundation
import Combine
import CoreLocation

/// Coordinates driving detection and a pause timer to derive a user-facing TravelState.
/// Transitions between Idle, Traveling, and Paused states based on motion updates,
/// publishing distances, durations, and paths for UI consumption.
@MainActor
final class RecordingManager {

    // MARK: - Singleton
    static let shared = RecordingManager()

    // MARK: - Dependencies
    private let travelStatePublisher: Published<TravelState>.Publisher
    private let locationPublisher: AnyPublisher<LocationPoint, Never>
    private let lastLocationPublisher: AnyPublisher<LocationPoint, Never>
    private let settings = SettingsManager.shared
    private let tripSegmentStore = SegmentStore.shared

    // MARK: - Published State (Outputs)
    @Published var isRecording: Bool = false
    @Published var tripStartTime: Date?
    @Published var tripDistanceLive: CLLocationDistance = 0
    @Published var tripDistanceCommitted: CLLocationDistance = 0
    @Published var tripDurationLive: TimeInterval = 0
    @Published var tripDurationCommitted: TimeInterval = 0
    @Published var commitedPath: [LocationPoint] = []
    @Published var nonCommitedPath: [LocationPoint] = []

    // MARK: - Private State
    private var compassHeading: CLLocationDirection?
    var pausedHeadingBuffer: [CLLocationDirection] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentLocation: LocationPoint?
    private var lastLocation: LocationPoint?
    private var previousState: TravelState?
    private var durationTimer: AnyCancellable?
    var liveSegment: TripSegment?
    var previousSegment: TripSegment?
    var pausedSegment: TripSegment?
    var pauseAnchor: LocationPoint?

    // MARK: - Init
    private init() {
        // Wire dependency publishers (kept as singletons per current architecture)
        travelStatePublisher = TravelStateManager.shared.$state
        locationPublisher = LocationManager.shared.locationPublisher
        lastLocationPublisher = LocationManager.shared.$lastLocation.compactMap { $0 }.eraseToAnyPublisher()

        bind()
    }

    // MARK: - Bindings
    private func bind() {
        travelStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleTravelStateUpdate(state)
            }
            .store(in: &cancellables)

        locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                self.currentLocation = location
                if self.isRecording {
                    self.liveSegment?.append(location: location)
                    self.tripDistanceLive = (self.previousSegment?.distance ?? 0) + (self.liveSegment?.distance ?? 0)
                    self.nonCommitedPath = self.liveSegment?.pathCoordinates ?? []
                }
            }
            .store(in: &cancellables)

        lastLocationPublisher
            .sink { [weak self] location in
                Task { @MainActor in
                    self?.lastLocation = location
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers (Logic)
    func reset() {
        isRecording = false
        previousState = .idle
        commitedPath = []
        nonCommitedPath = []
        tripStartTime = nil
        tripDistanceLive = 0
        tripDistanceCommitted = 0
        tripDurationLive = 0
        tripDurationCommitted = 0
        stopDurationTimer()
        liveSegment = nil
        previousSegment = nil
        pausedSegment = nil
        pauseAnchor = nil
    }

    func interpolatePoints(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, steps: Int) -> [CLLocationCoordinate2D] {
        guard steps > 0 else { return [to] }
        var result: [CLLocationCoordinate2D] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let lat = from.latitude + (to.latitude - from.latitude) * t
            let lon = from.longitude + (to.longitude - from.longitude) * t
            result.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return result
    }

    private func startDurationTimer() {
        durationTimer?.cancel()
        durationTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tripDurationLive += 1
            }
    }

    private func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
    }

    func handleTravelStateUpdate(_ state: TravelState) {
        switch state {
        case .traveling:
            transitionToTraveling()
        case .paused:
            transitionToPaused()
        case .idle:
            transitionToIdle()
        }
        previousState = state
        isRecording = (state == .traveling || state == .paused)
    }

    func transitionToTraveling() {
        if previousState == .paused {
            transitionFromPausedToTraveling()
        }

        startDurationTimer()
        if liveSegment == nil {
            tripStartTime = Date()
            liveSegment = TripSegment(startTimestamp: tripStartTime ?? Date())
        }
    }

    private func transitionFromPausedToTraveling() {
        guard var paused = pausedSegment, let anchor = pauseAnchor else { return }
        paused.duration = tripDurationLive

        if PauseSegmentClassifier.shouldMerge(
            paused,
            anchorHeading: anchor.course,
            headingBuffer: pausedHeadingBuffer
        ) {
            if var prev = previousSegment {
                prev.merge(with: paused)
                previousSegment = prev
                tripSegmentStore.update(prev)
                commitedPath = prev.pathCoordinates
            }
        } else {
            if let prev = previousSegment {
                if prev.distance >= settings.minDistanceMeters {
                    finalizeInMemory(prev)
                } else {
                    tripSegmentStore.delete(prev)
                }
            }
            previousSegment = paused
            tripSegmentStore.write(paused)
            commitedPath = paused.pathCoordinates
        }
        
        pausedSegment = nil
        pauseAnchor = nil
        pausedHeadingBuffer.removeAll()
        nonCommitedPath = []
        tripDistanceCommitted = previousSegment?.distance ?? 0
        tripDurationCommitted = previousSegment?.duration ?? 0
    }

    func transitionToPaused() {
        guard previousState == .traveling else { return }

        if var live = liveSegment {
            live.duration = tripDurationLive
            live.distance = tripDistanceLive
            
            if var prev = previousSegment {
                prev.merge(with: live)
                previousSegment = prev
                tripSegmentStore.update(prev)
            } else {
                previousSegment = live
                tripSegmentStore.write(live)
            }
            commitedPath = previousSegment?.pathCoordinates ?? []
        }
        
        startDurationTimer()
        nonCommitedPath = []

        if let ps = previousSegment {
            tripDurationCommitted = ps.duration
            tripDistanceCommitted = ps.distance
        }
        
        tripDistanceLive = 0
        liveSegment = nil

        pauseAnchor = currentLocation
        pausedSegment = TripSegment(startTimestamp: Date())
    }

    func transitionToIdle() {
        guard previousState == .paused || previousState == .traveling else { 
            reset()
            return 
        }

        if let location = currentLocation {
            let lastLocation = previousSegment?.pathCoordinates.last
            let currentCoordinate = location.coordinate
            if lastLocation == nil
                || lastLocation?.coordinate.latitude != currentCoordinate.latitude
                || lastLocation?.coordinate.longitude != currentCoordinate.longitude
            {
                previousSegment?.append(location: location)
            }
        }

        if let segment = previousSegment {
            if segment.distance >= settings.minDistanceMeters {
                finalizeInMemory(segment)
            } else {
                tripSegmentStore.delete(segment)
            }
        }
        reset()
    }

    private func finalizeInMemory(_ segment: TripSegment?) {
        guard var segment = segment else { return }
        segment.finalize(at: Date())
        self.tripSegmentStore.update(segment)
    }
}
