import Foundation
import Combine
import CoreLocation

final class RecordingManager {
    private let compassHeadingPublisher = LocationManager.shared.$compassHeading
    private var compassHeading: CLLocationDirection?
    private var pausedHeadingBuffer: [CLLocationDirection] = []
    private let recordingStore = RecordingStore()
    
    @Published var tripDistanceCommitted: CLLocationDistance = 0
    @Published var tripDistanceLive: CLLocationDistance = 0
    @Published var tripDurationCommitted: TimeInterval = 0
    @Published var tripDurationLive: TimeInterval = 0
    @Published var isRecording: Bool = false

    private var firstLocation: CLLocation?
    private var lastRecordedLocation: CLLocation?
    private var tripStartTime: Date?

    private let travelStatePublisher: Published<TravelStateManager.TravelState>.Publisher
    private let currentLocationPublisher: Published<CLLocation?>.Publisher
    private let lastLocationPublisher: Published<CLLocation?>.Publisher

    private var cancellables = Set<AnyCancellable>()
    private var currentLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var previousState: TravelStateManager.TravelState?
    private var durationTimer: AnyCancellable?

    private var liveSegment: TripSegment?
    private var previousSegment: TripSegment?
    private var pausedSegment: TripSegment?
    private var pauseAnchor: CLLocation?

    init(
        travelStatePublisher: Published<TravelStateManager.TravelState>.Publisher,
        currentLocationPublisher: Published<CLLocation?>.Publisher,
        lastLocationPublisher: Published<CLLocation?>.Publisher
    ) {
        self.travelStatePublisher = travelStatePublisher
        self.currentLocationPublisher = currentLocationPublisher
        self.lastLocationPublisher = lastLocationPublisher

        bindPublishers()
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
                      let _ = self.lastRecordedLocation,
                      let location = location else { return }

                self.lastRecordedLocation = location
                if var segment = self.liveSegment {
                    segment.append(location: location)
                    self.tripDistanceLive = segment.distance
                }
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

    private func handleTravelStateUpdate(_ state: TravelStateManager.TravelState) {
        switch state {
        case .traveling:
            if previousState == .paused {
                pausedSegment?.duration = tripDurationLive
                print("Paused segment duration set to \(tripDurationLive)")

                if let paused = pausedSegment, let anchor = pauseAnchor {
                    if PauseSegmentClassifier.shouldMerge(paused, anchorHeading: anchor.course, headingBuffer: pausedHeadingBuffer),
                       let previous = previousSegment {
                        previousSegment = TripSegment.merge(liveSegment: paused, previousSegment: previous)
                        recordingStore.updateTemporarySegment(previousSegment!)
                    } else {
                        previousSegment?.finalize(at: Date())
                        recordingStore.finalizeTemporarySegment()
                        previousSegment = nil
                    }
                    tripDistanceCommitted = previousSegment?.distance ?? 0
                    tripDurationCommitted = previousSegment?.duration ?? 0
                }
                pausedHeadingBuffer.removeAll()
            }
            startDurationTimer()

            var newSegment = TripSegment(startTimestamp: Date())
            if let current = currentLocation {
                newSegment.append(location: current)
            }

            liveSegment = newSegment
            if let previous = previousSegment {
                recordingStore.updateTemporarySegment(previous)
            }
            pausedSegment = nil
            pauseAnchor = nil

            if firstLocation == nil, let location = currentLocation {
                firstLocation = location
                lastRecordedLocation = location
            }

            if let location = currentLocation {
                
            }
            if let live = liveSegment {
                recordingStore.writeTemporarySegment(live)
            }

        case .paused:
            liveSegment?.duration = tripDurationLive
            liveSegment?.distance = tripDistanceLive
            startDurationTimer()

            if let previous = previousSegment, let live = liveSegment {
                previousSegment = TripSegment.merge(liveSegment: live, previousSegment: previous)
                recordingStore.updateTemporarySegment(previousSegment!)
            } else if let live = liveSegment {
                previousSegment = live
                recordingStore.writeTemporarySegment(previousSegment!)
            }
            
            tripDurationCommitted = previousSegment?.duration ?? 0
            tripDistanceCommitted = previousSegment?.distance ?? 0
            tripDistanceLive = 0
            liveSegment = nil

            pauseAnchor = currentLocation
            pausedSegment = TripSegment(startTimestamp: Date())
            if let current = currentLocation {
                pausedSegment?.append(location: current)
            }

        case .idle:
            if let location = currentLocation {
                if var active = liveSegment {
                    active.append(location: location)
                    active.finalize(at: Date())
                    recordingStore.finalizeTemporarySegment()
                }
            }

            finalizeCurrentSegment()
            reset()
        }

        previousState = state
        isRecording = (state == .traveling)
    }

    private func finalizeCurrentSegment() {
        if var active = liveSegment {
            active.finalize(at: Date())
        }
    }

    private func reset() {
        firstLocation = nil
        lastRecordedLocation = nil
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
                      let start = self.tripStartTime else { return }
                self.tripDurationLive = Date().timeIntervalSince(start)
            }
    }

    private func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
    }

    func interpolatePoints(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, steps: Int) -> [CLLocationCoordinate2D] {
        guard steps > 1 else { return [to] }
        let latStep = (to.latitude - from.latitude) / Double(steps)
        let lonStep = (to.longitude - from.longitude) / Double(steps)
        return (1..<steps).map { i in
            CLLocationCoordinate2D(latitude: from.latitude + latStep * Double(i),
                                   longitude: from.longitude + lonStep * Double(i))
        } + [to]
    }
}
