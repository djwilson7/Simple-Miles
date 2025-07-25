import SwiftUI
import Foundation
import Combine
import CoreLocation
import CoreML


final class TravelStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: TravelState = .idle
    @Published var pauseRemainingTime: TimeInterval? = nil
    @Published private(set) var pauseTotalDuration: TimeInterval? = nil
    private var pauseTimer: Timer?
    private let defaultPauseDuration: TimeInterval = 1200.0
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

    // MARK: - Init
    init(
        drivingStatePublisher: Published<Bool>.Publisher,
        locationManager: LocationManager
    ) {
        self.locationManager = locationManager
        // Ensure pause times are nil on init for clean state
        pauseRemainingTime = nil
        pauseTotalDuration = nil
        subscribeToDrivingState(publisher: drivingStatePublisher)
    }

    // MARK: - Subscriptions
    private func subscribeToDrivingState(publisher: Published<Bool>.Publisher) {
        drivingStateCancellable = publisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDriving in
                self?.handleDrivingStateChange(isDriving)
            }
    }

    // MARK: - Driving State Handling
    private func handleDrivingStateChange(_ isDriving: Bool) {
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
        pauseRemainingTime = defaultPauseDuration
        pauseTotalDuration = defaultPauseDuration

        // TripStartModel prediction logic
//        if let modelURL = ModelStore.shared.modelURL {
//            do {
//                let mlModel = try MLModel(contentsOf: modelURL)
//                let model = TripStartModel(model: mlModel)
//                if let event = MotionManager.shared.currentEvent(label: "pre_check") {
//                    let prediction = model.predict(samples: event.samples)
//                    print("[TravelStateManager] (TripStartModel Prediction) - result: \(prediction)")
//                } else {
//                    print("[TravelStateManager] (TripStartModel Prediction) - Failed to get prediction, event is nil")
//                }
//            } catch {
//                print("[TravelStateManager] (TripStartModel Prediction) - Prediction failed: \(error)")
//            }
//        } else {
//            print("[TravelStateManager] (TripStartModel Prediction) - No model available, using fallback logic")
//        }
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

    func extendPauseTimer(by interval: TimeInterval = 600) {
        if let current = pauseRemainingTime {
            pauseRemainingTime = current + interval
        } else {
            pauseRemainingTime = interval
        }

        if let total = pauseTotalDuration {
            pauseTotalDuration = total + interval
        } else {
            pauseTotalDuration = interval
        }
    }

    // MARK: - State Mutation
    func markAsTraveling() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        state = .traveling
    }

    func markAsPaused() {
        state = .paused
        pauseTimer?.invalidate()
        pauseRemainingTime = defaultPauseDuration
        pauseTotalDuration = defaultPauseDuration

        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard let remaining = self.pauseRemainingTime else { return }

            if remaining <= 1 {
                timer.invalidate()
                self.pauseRemainingTime = nil
                self.pauseTotalDuration = nil
                self.markAsIdle()
            } else {
                self.pauseRemainingTime = remaining - 1
            }
        }
    }

    func markAsIdle() {
        pauseRemainingTime = nil
        pauseTotalDuration = nil
        state = .idle
    }

}
