import SwiftUI
import Foundation
import Combine
import CoreLocation
import CoreML


final class TravelStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: TravelState = .idle
    @Published var pauseTimerInterval: TimeInterval = 120
    @Published private(set) var totalPauseTimerDuration: TimeInterval = 120
    private let pauseTime = 20.0
    // MARK: - State Enum
    enum TravelState {
        case idle
        case traveling
        case paused
        
        var displayText: String {
            switch self {
            case .idle: return "Idle"
            case .traveling: return "Traveling"
            case .paused: return "Paused"
            }
        }

        var color: Color {
            switch self {
            case .idle: return .gray
            case .traveling: return .green
            case .paused: return .orange
            }
        }
    }

    // MARK: - Private Properties
    private var drivingStateCancellable: AnyCancellable?
    private var locationManager: LocationManager?
    private var pauseStartTime: Date?
    private var pauseTimer: Timer?

    // MARK: - Init
    init(
        drivingStatePublisher: Published<Bool>.Publisher,
        locationManager: LocationManager
    ) {
        self.locationManager = locationManager
        subscribeToDrivingState(publisher: drivingStatePublisher)
    }

    // MARK: - Subscriptions
    private func subscribeToDrivingState(publisher: Published<Bool>.Publisher) {
        print("[TravelStateManager] (subscribeToDrivingState) - Subscribing to driving state changes")
        drivingStateCancellable = publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDriving in
                self?.handleDrivingStateChange(isDriving)
            }
    }

    // MARK: - Driving State Handling
    private func handleDrivingStateChange(_ isDriving: Bool) {
        print("[TravelStateManager] (handleDrivingStateChange) - Driving state changed: \(isDriving)")
        switch isDriving {
        case true:
            handleDrivingStarted()
        case false:
            handleDrivingStopped()
        }
    }

    private func handleDrivingStarted() {
        guard state != .traveling else {
            print("[TravelStateManager] (handleDrivingStarted) - Already in .traveling, skipping.")
            return
        }
        print("[TravelStateManager] (handleDrivingStarted) - Driving started, transitioning to traveling")
        pauseTimerInterval = pauseTime
        totalPauseTimerDuration = pauseTime

        // TripStartModel prediction logic
        if let modelURL = ModelStore.shared.modelURL {
            do {
                let mlModel = try MLModel(contentsOf: modelURL)
                let model = TripStartModel(model: mlModel)
                if let event = MotionManager.shared.currentEvent(label: "pre_check") {
                    let prediction = model.predict(samples: event.samples)
                    print("[TravelStateManager] (TripStartModel Prediction) - result: \(prediction)")
                } else {
                    print("[TravelStateManager] (TripStartModel Prediction) - Failed to get prediction, event is nil")
                }
            } catch {
                print("[TravelStateManager] (TripStartModel Prediction) - Prediction failed: \(error)")
            }
        } else {
            print("[TravelStateManager] (TripStartModel Prediction) - No model available, using fallback logic")
        }
        markAsTraveling()
    }

    private func handleDrivingStopped() {
        print("[TravelStateManager] (handleDrivingStopped) - Driving stopped, transitioning to paused and starting idle timer")
        guard state == .traveling else {
            print("[TravelStateManager] (handleDrivingStopped) - Ignoring transition to paused, current state is not .traveling")
            return
        }
        markAsPaused()
    }

    func extendPauseTimer(by interval: TimeInterval) {
        print("[TravelStateManager] (extendPauseTimer) - Extending pause timer by \(interval) seconds")
        pauseTimerInterval += interval
    }

    // MARK: - State Mutation
    func markAsTraveling() {
        print("[TravelStateManager] (markAsTraveling) - State updated to .traveling")
        pauseTimer?.invalidate()
        pauseTimer = nil
        state = .traveling
    }

    func markAsPaused() {
        print("[TravelStateManager] (markAsPaused) - State updated to .paused")
        state = .paused
        pauseTimerInterval = pauseTime
        totalPauseTimerDuration = pauseTime
        pauseStartTime = Date()
        schedulePauseProgressUpdater()
    }

    func markAsIdle() {
        print("[TravelStateManager] (markAsIdle) - State updated to .idle")
        state = .idle
    }

    private func schedulePauseProgressUpdater() {
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] timer in
            guard let self, let start = self.pauseStartTime else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(start)
            let remaining = max(self.pauseTime - elapsed, 0)
            self.pauseTimerInterval = remaining

            if remaining <= 0 {
                timer.invalidate()
                self.markAsIdle()
            }
        }
    }
}
