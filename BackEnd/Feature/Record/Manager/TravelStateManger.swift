import Foundation
import Combine
import CoreLocation
import SwiftUI

/// Coordinates driving detection and a pause timer to derive a user-facing TravelState.
/// Publishes the current state and pause timing for UI consumption.
@MainActor
final class TravelStateManager: ObservableObject {

    // MARK: - Singleton
    static let shared = TravelStateManager()

    // MARK: - Dependencies
    private let drivingStateManager = DrivingStateManager.shared
    private let settings = SettingsManager.shared

    // MARK: - Published State (Outputs)
    @Published private(set) var state: TravelState = .idle
    @Published var pauseRemainingTime: TimeInterval? = nil
    @Published private(set) var pauseTotalDuration: TimeInterval? = nil

    // MARK: - Private State
    private var pauseTimer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        pauseRemainingTime = nil
        pauseTotalDuration = nil
        bindDrivingState()
    }

    // MARK: - Public API (Intents)
    /// Extends the current pause timer by the configured interval.
    /// If no timer is active, starts a new pause window with that interval.
    func extendPauseTimer() {
        let interval = settings.pauseTimer

        // Extend remaining
        if let current = pauseRemainingTime {
            pauseRemainingTime = current + interval
        } else {
            pauseRemainingTime = interval
        }

        // Extend total
        if let total = pauseTotalDuration {
            pauseTotalDuration = total + interval
        } else {
            pauseTotalDuration = interval
        }
    }

    // MARK: - Bindings (Streams wiring)
    private func bindDrivingState() {
        drivingStateManager.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDriving in
                guard let self else { return }
                self.handleDrivingStateChange(isDriving)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    private func handleDrivingStateChange(_ isDriving: Bool) {
        if isDriving {
            handleDrivingStarted()
        } else {
            handleDrivingStopped()
        }
    }

    private func handleDrivingStarted() {
        guard state != .traveling else { return }

        // Initialize a fresh pause window as we enter traveling.
        pauseRemainingTime = settings.pauseTimer
        pauseTotalDuration = settings.pauseTimer

        // Stop any pause countdown.
        pauseTimer?.cancel()
        pauseTimer = nil

        state = .traveling
        print("TravelState Transitioned: .traveling")
    }

    private func handleDrivingStopped() {
        guard state == .traveling else { return }

        state = .paused
        print("TravelState Transitioned: .paused")

        // Reset pause window and start countdown.
        pauseRemainingTime = settings.pauseTimer
        pauseTotalDuration = settings.pauseTimer

        startPauseCountdown()
    }

    private func startPauseCountdown() {
        pauseTimer?.cancel()
        pauseTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard let remaining = self.pauseRemainingTime else { return }

                if remaining <= 1 {
                    // End pause window -> transition to idle.
                    self.pauseTimer?.cancel()
                    self.pauseTimer = nil
                    self.pauseRemainingTime = nil
                    self.pauseTotalDuration = nil
                    self.state = .idle
                    print("TravelState Transitioned: .idle (pause timer expired)")
                } else {
                    self.pauseRemainingTime = remaining - 1
                }
            }
    }

    // MARK: - Deinit
    deinit {
        pauseTimer?.cancel()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
