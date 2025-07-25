import Foundation
import Combine
import CoreLocation

final class RecordingManager {
    @Published var tripDistance: CLLocationDistance = 0
    @Published var tripDuration: TimeInterval = 0
    @Published var isRecording: Bool = false

    private var firstLocation: CLLocation?
    private var lastRecordedLocation: CLLocation?
    private var tripStartTime: Date?
    private var lastHeading: CLLocationDirection?

    private let travelStatePublisher: Published<TravelStateManager.TravelState>.Publisher
    private let currentLocationPublisher: Published<CLLocation?>.Publisher
    private let lastLocationPublisher: Published<CLLocation?>.Publisher

    private var cancellables = Set<AnyCancellable>()
    private var currentLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var previousState: TravelStateManager.TravelState?
    private var durationTimer: AnyCancellable?

    init(
        travelStatePublisher: Published<TravelStateManager.TravelState>.Publisher,
        currentLocationPublisher: Published<CLLocation?>.Publisher,
        lastLocationPublisher: Published<CLLocation?>.Publisher
    ) {
        self.travelStatePublisher = travelStatePublisher
        self.currentLocationPublisher = currentLocationPublisher
        self.lastLocationPublisher = lastLocationPublisher

        travelStatePublisher
            .sink { [weak self] state in
                self?.handleTravelStateUpdate(state)
            }
            .store(in: &cancellables)

        currentLocationPublisher
            .sink { [weak self] location in
                self?.currentLocation = location
                guard let self = self,
                      self.isRecording,
                      let last = self.lastRecordedLocation,
                      let location = location else { return }

                let distance = last.distance(from: location)
                self.tripDistance += distance
                self.lastRecordedLocation = location
            }
            .store(in: &cancellables)

        lastLocationPublisher
            .sink { [weak self] location in
                self?.lastLocation = location
            }
            .store(in: &cancellables)
    }

    private func handleTravelStateUpdate(_ state: TravelStateManager.TravelState) {
        switch state {
        case .traveling:
            guard let location = currentLocation else { return }

            if previousState == .idle {
            }

            if firstLocation == nil {
                firstLocation = location
                tripStartTime = location.timestamp
                if durationTimer == nil {
                    durationTimer = Timer.publish(every: 1.0, on: .main, in: .common)
                        .autoconnect()
                        .sink { [weak self] _ in
                            guard let self = self,
                                  self.isRecording,
                                  let start = self.tripStartTime else { return }
                            self.tripDuration = Date().timeIntervalSince(start)
                        }
                }
                tripDistance = 0
                tripDuration = 0
                lastRecordedLocation = location
            }

            RecordingStore.updateLivePath(location)
        case .paused:
            durationTimer?.cancel()
            durationTimer = nil
        case .idle:
            if let location = currentLocation {
                RecordingStore.finalizeLivePath(location)
            }
            firstLocation = nil
            lastRecordedLocation = nil
            tripStartTime = nil
            tripDistance = 0
            durationTimer?.cancel()
            durationTimer = nil
        }
        previousState = state
        isRecording = (state == .traveling)
    }
}

private extension RecordingManager {
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
