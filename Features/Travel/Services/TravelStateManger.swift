/// TravelStateManger.swift
/// 
/// Manages the travel state of the user based on driving detection and timer events.
/// This includes transitioning between traveling, paused, and idle states. It observes
/// driving state changes, manages pause timers, and handles pause extension requests
/// from app group shared defaults.

import SwiftUI
import Foundation
import Combine
import CoreLocation
import CoreML
import NotificationCenter


/// Manages the travel state of the user by observing driving status and handling timers.
/// This singleton class tracks whether the user is traveling, paused, or idle, manages
/// pause durations, and responds to external pause extension triggers.
/// It facilitates the coordination between driving detection and travel state transitions.
@MainActor
final class TravelStateManager: ObservableObject {
    static let shared = TravelStateManager()
    
    // MARK: - Published Properties
    /// Remaining time for the current pause duration.
    /// Updated every second when paused and nil otherwise.
    @Published var pauseRemainingTime: TimeInterval? = nil
    
    /// The current travel state of the user, such as idle, traveling, or paused.
    /// This property is read-only externally to prevent uncontrolled mutations.
    @Published private(set) var state: TravelState = .idle
    
    /// The total duration initially set for the current pause period.
    /// This represents the original pause timer length and is nil when not paused.
    @Published private(set) var pauseTotalDuration: TimeInterval? = nil

    // MARK: - Timer Properties
    /// Timer instance responsible for decrementing the pauseRemainingTime.
    private var pauseTimer: Timer?
    
    /// Timer periodically checking for external pause extension triggers.
    private var extendPauseFlagTimer: Timer?
    
    // MARK: - Observer/Cancellable Properties
    /// Observer for notification center events, currently unused but reserved.
    private var notificationObserver: NSObjectProtocol?
    
    /// Cancellable token for the Combine subscription to driving state publisher.
    private var drivingStateCancellable: AnyCancellable?

    // MARK: - Manager Dependencies
    /// Shared location manager used for any location-related functionalities.
    private let locationManager = LocationManager.shared
    
    /// Shared driving state manager which provides driving state changes.
    private let drivingStateManager = DrivingStateManager.shared
    
    private let settings = SettingsCenter.shared
    // MARK: - Init
    /// Private initializer to enforce singleton usage pattern.
    /// Ensures only one instance of TravelStateManager exists during app lifecycle.
    private init() {
        pauseRemainingTime = nil
        pauseTotalDuration = nil
        subscribeToDrivingState()
    }

    // MARK: - Public Methods
    /// Extends the current pause timer duration by the configured pause timer interval.
    /// Updates both remaining and total pause durations accordingly.
    /// If no pause timer exists, initializes it with the default interval.
    func extendPauseTimer() {
        let interval = settings.pauseTimer //always pulled from settings.
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

    // MARK: - Private Methods
    /// Subscribes to driving state changes from the drivingStateManager,
    /// observing on the main thread and handling duplicates.
    /// Updates the internal travel state accordingly.
    private func subscribeToDrivingState() {
        drivingStateCancellable = drivingStateManager.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDriving in
                self?.handleDrivingStateChange(isDriving)
            }
    }

    /// Handles changes in driving state by delegating to appropriate handlers
    /// depending on whether driving has started or stopped.
    /// - Parameter isDriving: Boolean indicating current driving status.
    private func handleDrivingStateChange(_ isDriving: Bool) {
        switch isDriving {
        case true:
            handleDrivingStarted()
        case false:
            handleDrivingStopped()
        }
    }

    /// Called when driving starts.
    /// Resets and invalidates any pause timers, sets the state to traveling,
    /// and initializes pause timers from app settings.
    private func handleDrivingStarted() {
        guard state != .traveling else { return }
        pauseRemainingTime = settings.pauseTimer
        pauseTotalDuration = settings.pauseTimer
        pauseTimer?.invalidate()
        pauseTimer = nil
        
        extendPauseFlagTimer?.invalidate()
        extendPauseFlagTimer = nil
        
        state = .traveling
        print("TravelState Transitioned: .traveling")
    }

    /// Called when driving stops.
    /// Transitions state to paused, starts a countdown timer for the pause duration,
    /// and sets up a periodic timer to listen for external pause extension requests.
    /// When the pause timer expires, transitions the state to idle.
    private func handleDrivingStopped() {
        guard state == .traveling else {
            return
        }
        state = .paused
        print("TravelState Transitioned: .paused")
        pauseTimer?.invalidate()
        pauseRemainingTime = settings.pauseTimer
        pauseTotalDuration = settings.pauseTimer

        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return }
                guard let remaining = self.pauseRemainingTime else { return }

                if remaining <= 1 {
                    timer.invalidate()
                    self.pauseRemainingTime = nil
                    self.pauseTotalDuration = nil
                    
                    self.extendPauseFlagTimer?.invalidate()
                    self.extendPauseFlagTimer = nil
                    
                    self.state = .idle
                    print("TravelState Transitioned: .idle (pause timer expired)")
                } else {
                    self.pauseRemainingTime = remaining - 1
                }
            }
        }
        
        if extendPauseFlagTimer == nil {
            extendPauseFlagTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if getSharedDefaults()?.bool(forKey: SharedKeys.extendPauseRequested) == true {
                    print("App Group flag triggered: extending pause timer.")
                    Task { @MainActor in
                        self.extendPauseTimer()
                    }
                    getSharedDefaults()?.set(false, forKey: SharedKeys.extendPauseRequested)
                }
            }
        }
    }

    /// Cleans up any observers and invalidates timers upon deallocation.
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        extendPauseFlagTimer?.invalidate()
    }

}
