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

    init(
        travelStatePublisher: Published<TravelStateManager.TravelState>.Publisher,
        currentLocationPublisher: Published<CLLocation?>.Publisher,
        lastLocationPublisher: Published<CLLocation?>.Publisher
    ) {
        print("[RecordingManager] (init) - Initializing subscriptions to state and location publishers.")
        self.travelStatePublisher = travelStatePublisher
        self.currentLocationPublisher = currentLocationPublisher
        self.lastLocationPublisher = lastLocationPublisher

        travelStatePublisher
            .sink { [weak self] state in
                print("[RecordingManager] (travelStatePublisher) - State changed to: \(state)")
                self?.handleTravelStateUpdate(state)
            }
            .store(in: &cancellables)

        currentLocationPublisher
            .sink { [weak self] location in
                print("[RecordingManager] (currentLocationPublisher) - Updated current location: \(String(describing: location))")
                self?.currentLocation = location
            }
            .store(in: &cancellables)

        lastLocationPublisher
            .sink { [weak self] location in
                print("[RecordingManager] (lastLocationPublisher) - Updated last location: \(String(describing: location))")
                self?.lastLocation = location
            }
            .store(in: &cancellables)
    }

    private func handleTravelStateUpdate(_ state: TravelStateManager.TravelState) {
        print("[RecordingManager] (handleTravelStateUpdate) - Handling travel state: \(state)")
        switch state {
        case .traveling:
            guard let location = currentLocation else { return }

            if previousState == .idle {
                print("[RecordingManager] (handleTravelStateUpdate) - First traveling update.")
            }

            if firstLocation == nil {
                firstLocation = location
                tripStartTime = location.timestamp
                tripDistance = 0
                tripDuration = 0
                lastRecordedLocation = location
                print("[RecordingManager] (handleTravelStateUpdate) - First location set. Resetting trip metrics.")
            } else if let last = lastRecordedLocation {
                let distance = last.distance(from: location)
                tripDistance += distance
                lastRecordedLocation = location
                print("[RecordingManager] (handleTravelStateUpdate) - Added distance: \(distance). Total: \(tripDistance)")
            }

            if let startTime = tripStartTime {
                tripDuration = location.timestamp.timeIntervalSince(startTime)
                print("[RecordingManager] (handleTravelStateUpdate) - Updated duration: \(tripDuration)")
            }

            RecordingStore.updateLivePath(location)
        case .paused:
            // Do nothing during pause
            break
        case .idle:
            if let location = currentLocation {
                print("[RecordingManager] (handleTravelStateUpdate) - Finalizing trip with last location.")
                RecordingStore.finalizeLivePath(location)
            }
            firstLocation = nil
            lastRecordedLocation = nil
            tripStartTime = nil
            tripDistance = 0
            tripDuration = 0
            print("[RecordingManager] (handleTravelStateUpdate) - Trip metrics reset.")
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
