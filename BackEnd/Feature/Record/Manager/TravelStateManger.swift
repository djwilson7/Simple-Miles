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
    private let drivingStateManager: DrivingStateManager
    private let settings: SettingsManager

    // MARK: - Published State (Outputs)
    @Published var state: TravelState = .idle
    @Published var pauseRemainingTime: TimeInterval? = nil
    @Published var pauseTotalDuration: TimeInterval? = nil

    // MARK: - Private State
    var pauseTimer: AnyCancellable?
    var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(drivingStateManager: DrivingStateManager? = nil, settings: SettingsManager? = nil) {
        self.drivingStateManager = drivingStateManager ?? .shared
        self.settings = settings ?? .shared
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
    func bindDrivingState() {
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
    func handleDrivingStateChange(_ isDriving: Bool) {
        if isDriving {
            handleDrivingStarted()
        } else {
            handleDrivingStopped()
        }
    }

    func handleDrivingStarted() {
        guard state != .traveling else { return }

        // Stop any pause countdown.
        pauseTimer?.cancel()
        pauseTimer = nil
        
        // Clear pause window state when starting to drive
        pauseRemainingTime = nil
        pauseTotalDuration = nil

        state = .traveling
        print("TravelState Transitioned: .traveling")
    }

    func handleDrivingStopped() {
        guard state == .traveling else { return }

        state = .paused
        print("TravelState Transitioned: .paused")

        // Reset pause window only if not already set (e.g. by extendPauseTimer while traveling)
        if pauseRemainingTime == nil {
            pauseRemainingTime = settings.pauseTimer
            pauseTotalDuration = settings.pauseTimer
        }

        startPauseCountdown()
    }

    func startPauseCountdown() {
        pauseTimer?.cancel()
        
        var lastFire = Date()
        
        pauseTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard let remaining = self.pauseRemainingTime else {
                    self.pauseTimer?.cancel()
                    self.pauseTimer = nil
                    return
                }
                
                let now = Date()
                let elapsed = now.timeIntervalSince(lastFire)
                lastFire = now
                
                let newRemaining = remaining - elapsed
                
                if newRemaining <= 0 {
                    // End pause window -> transition to idle.
                    self.pauseTimer?.cancel()
                    self.pauseTimer = nil
                    self.pauseRemainingTime = nil
                    self.pauseTotalDuration = nil
                    self.state = .idle
                    print("TravelState Transitioned: .idle (pause timer expired)")
                } else {
                    self.pauseRemainingTime = newRemaining
                }
            }
    }

    func reset() {
        state = .idle
        pauseRemainingTime = nil
        pauseTotalDuration = nil
        pauseTimer?.cancel()
        pauseTimer = nil
        cancellables.removeAll()
        bindDrivingState()
    }
}
