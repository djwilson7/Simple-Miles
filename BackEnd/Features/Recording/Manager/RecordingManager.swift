import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class RecordingManager {
    static let shared = RecordingManager()

    private init() {
        travelStatePublisher = TravelStateManager.shared.$state
        currentLocationPublisher = LocationManager.shared.$currentLocation
        lastLocationPublisher = LocationManager.shared.$lastLocation
        bindPublishers()
    }

    private let compassHeadingPublisher = LocationManager.shared.$compassHeading
    private var travelStatePublisher: Published<TravelState>.Publisher!
    private var currentLocationPublisher: Published<LocationPoint?>.Publisher!
    private var lastLocationPublisher: Published<LocationPoint?>.Publisher!
    private let tripSegmentStore = SegmentStore.shared
    private let settings = SettingsManager.shared

    @Published var tripDistanceCommitted: CLLocationDistance = 0
    @Published var tripDistanceLive: CLLocationDistance = 0
    @Published var tripDurationCommitted: TimeInterval = 0
    @Published var tripDurationLive: TimeInterval = 0
    @Published var isRecording: Bool = false
    @Published var commitedPath: [LocationPoint] = []
    @Published var nonCommitedPath: [LocationPoint] = []

    private var compassHeading: CLLocationDirection?
    private var pausedHeadingBuffer: [CLLocationDirection] = []
    private var tripStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var currentLocation: LocationPoint?
    private var lastLocation: LocationPoint?
    private var previousState: TravelState?
    private var durationTimer: AnyCancellable?
    private var liveSegment: TripSegment?
    private var previousSegment: TripSegment?
    private var pausedSegment: TripSegment?
    private var pauseAnchor: LocationPoint?

    func interpolatePoints(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        steps: Int
    ) -> [CLLocationCoordinate2D] {
        guard steps > 1 else { return [to] }
        let latStep = (to.latitude - from.latitude) / Double(steps)
        let lonStep = (to.longitude - from.longitude) / Double(steps)
        return (1..<steps).map { i in
            CLLocationCoordinate2D(
                latitude: from.latitude + latStep * Double(i),
                longitude: from.longitude + lonStep * Double(i)
            )
        } + [to]
    }

    private func bindPublishers() {
        travelStatePublisher
            .sink { [weak self] state in self?.handleTravelStateUpdate(state) }
            .store(in: &cancellables)

        currentLocationPublisher
            .sink { [weak self] location in
                guard let self = self else { return }
                self.currentLocation = location
                guard self.isRecording,
                    let location = location
                else { return }

                self.liveSegment?.append(location: location)
                self.nonCommitedPath = self.liveSegment?.pathCoordinates ?? []
                self.tripDistanceLive = self.liveSegment?.distance ?? 0
            }
            .store(in: &cancellables)

        lastLocationPublisher
            .sink { [weak self] location in self?.lastLocation = location }
            .store(in: &cancellables)

        compassHeadingPublisher
            .sink { [weak self] heading in
                guard let self = self else { return }
                self.compassHeading = heading
                if self.previousState == .paused {
                    self.pausedHeadingBuffer.append(heading)
                }
            }
            .store(in: &cancellables)
    }

    private func reset() {
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

    private func startDurationTimer() {
        stopDurationTimer()
        tripStartTime = Date()
        durationTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                    let start = self.tripStartTime
                else { return }
                self.tripDurationLive = Date().timeIntervalSince(start)
            }
    }

    private func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
    }

    private func handleTravelStateUpdate(_ state: TravelState) {
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

    private func transitionToTraveling() {
        if previousState == .paused {
            transitionFromPausedToTraveling()
        }

        startDurationTimer()

        liveSegment = TripSegment(startTimestamp: Date())
        if currentLocation != nil {
            liveSegment!.append(location: currentLocation!)
        }
    }

    private func transitionFromPausedToTraveling() {
        pausedSegment?.duration = tripDurationLive

        if PauseSegmentClassifier.shouldMerge(
            pausedSegment!,
            anchorHeading: pauseAnchor!.course,
            headingBuffer: pausedHeadingBuffer
        ) {
            previousSegment!.merge(with: pausedSegment!)
            tripSegmentStore.update(previousSegment!)
            commitedPath = previousSegment!.pathCoordinates
        } else {
            if previousSegment!.distance >= settings.minDistanceMeters {
                finalizeInMemory(previousSegment!)
                previousSegment = pausedSegment
                tripSegmentStore.write(previousSegment!)
            } else {
                tripSegmentStore.delete(previousSegment!)
                previousSegment = nil
            }
            commitedPath = []
        }
        nonCommitedPath = []
        tripDistanceCommitted = previousSegment?.distance ?? 0
        tripDurationCommitted = previousSegment?.duration ?? 0
        pausedHeadingBuffer.removeAll()
        pauseAnchor = nil
    }

    private func transitionToPaused() {
        guard previousState == .traveling else { return }

        liveSegment?.duration = tripDurationLive
        liveSegment?.distance = tripDistanceLive
        startDurationTimer()

        if previousSegment != nil {
            previousSegment?.merge(with: liveSegment!)
            tripSegmentStore.update(previousSegment!)
        } else {
            previousSegment = liveSegment
            commitedPath = previousSegment!.pathCoordinates
            tripSegmentStore.write(previousSegment!)
        }
        nonCommitedPath = []

        tripDurationCommitted = previousSegment!.duration
        tripDistanceCommitted = previousSegment!.distance
        tripDistanceLive = 0
        liveSegment = nil

        pauseAnchor = currentLocation
        pausedSegment = TripSegment(startTimestamp: Date())
        if let current = currentLocation {
            pausedSegment?.append(location: current)
        }
    }

    private func transitionToIdle() {
        guard previousState == .paused else { return }

        if let location = currentLocation {
            let lastLocation = previousSegment?.pathCoordinates.last
            let currentCoordinate = location.coordinate
            if lastLocation == nil
                || lastLocation?.coordinate.latitude
                    != currentCoordinate.latitude
                || lastLocation?.coordinate.longitude
                    != currentCoordinate.longitude
            {
                previousSegment?.append(location: location)
            }
        }

        if previousSegment!.distance >= settings.minDistanceMeters {
            finalizeInMemory(previousSegment!)
        } else {
            tripSegmentStore.delete(previousSegment!)
        }
        reset()
    }

    private func finalizeInMemory(_ segment: TripSegment?) {
        guard var segment = segment else { return }
        segment.finalize(at: Date())
        self.tripSegmentStore.update(segment)
    }
}
