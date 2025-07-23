import Foundation
import CoreMotion
import Combine

final class MotionManager {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 50.0 // 50 Hz
    private let collector = MotionDataCollector()
    private var cancellables = Set<AnyCancellable>()
    private let motionQueue = OperationQueue()
    private var hasLoggedTravelingEvent = false
    private var oldTravelState: TravelStateManager.TravelState = .idle
    
    private init() {
        startStreaming()
    }

    func observeTravelState(_ travelStatePublisher: AnyPublisher<TravelStateManager.TravelState, Never>) {
        travelStatePublisher
            .sink { [weak self] state in
                guard let self = self else { return }
                print("[MotionManager] Travel state changed to: \(state)")

                switch state {
                case .traveling:
                    if self.hasLoggedTravelingEvent {
                        print("[MotionManager] Already logged traveling event. Skipping.")
                        return
                    }

                    self.hasLoggedTravelingEvent = true
                    if oldTravelState == .paused {
                        if let event = self.collector.extractLabeledEvent(label: "resumed_driving") {
                            MotionEventStore.shared.append(event)
                            print("[MotionManager] resumed_driving event stored.")
                        }
                    } else {
                        if let event = self.collector.extractLabeledEvent(label: "trip_start") {
                            MotionEventStore.shared.append(event)
                            print("[MotionManager] trip_start event stored.")
                        }
                    }
                case .paused:
                    if let event = self.collector.extractLabeledEvent(label: "movement_pause") {
                        MotionEventStore.shared.append(event)
                        print("[MotionManager] movement_pause event stored.")
                    }
                    self.hasLoggedTravelingEvent = false
                case .idle:
                    //no-op
                    self.hasLoggedTravelingEvent = false
                }
                oldTravelState = state
            }
            .store(in: &cancellables)
    }

    func startStreaming() {
        guard motionManager.isAccelerometerAvailable else {
            print("[MotionManager] Accelerometer not available.")
            return
        }

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, _ in
            guard let self = self, let accel = data?.acceleration else { return }
            self.collector.addSample(x: accel.x, y: accel.y, z: accel.z)
        }

        print("[MotionManager] Accelerometer streaming started.")
    }

    func stopStreaming() {
        motionManager.stopAccelerometerUpdates()
    }

    func currentEvent(label: String) -> MotionEvent? {
        return collector.extractLabeledEvent(label: label)
    }

    func clearBuffer() {
        collector.clear()
    }
}
