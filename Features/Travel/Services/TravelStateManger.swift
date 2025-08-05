import SwiftUI
import Foundation
import Combine
import CoreLocation
import CoreML
import NotificationCenter


final class TravelStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: TravelState = .idle
    @Published var pauseRemainingTime: TimeInterval? = nil
    @Published private(set) var pauseTotalDuration: TimeInterval? = nil
    private var pauseTimer: Timer?
    private var notificationObserver: NSObjectProtocol?
    private var extendPauseFlagTimer: Timer?

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
        guard state != .traveling else { return }
        pauseRemainingTime = AppSettings.shared.pauseTimer
        pauseTotalDuration = AppSettings.shared.pauseTimer
        pauseTimer?.invalidate()
        pauseTimer = nil
        
        extendPauseFlagTimer?.invalidate()
        extendPauseFlagTimer = nil
        
        state = .traveling
        print("TravelState Transitioned: .traveling")
    }

    private func handleDrivingStopped() {
        guard state == .traveling else {
            return
        }
        state = .paused
        print("TravelState Transitioned: .paused")
        pauseTimer?.invalidate()
        pauseRemainingTime = AppSettings.shared.pauseTimer
        pauseTotalDuration = AppSettings.shared.pauseTimer

        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard let remaining = self.pauseRemainingTime else { return }

            if remaining <= 1 {
                timer.invalidate()
                self.pauseRemainingTime = nil
                self.pauseTotalDuration = nil
                
                // Invalidate and nil extendPauseFlagTimer here as per instructions
                self.extendPauseFlagTimer?.invalidate()
                self.extendPauseFlagTimer = nil
                
                self.state = .idle
                print("TravelState Transitioned: .idle (pause timer expired)")
            } else {
                self.pauseRemainingTime = remaining - 1
            }
        }
        
        // Create and start extendPauseFlagTimer here as per instructions
        if extendPauseFlagTimer == nil {
            extendPauseFlagTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if getSharedDefaults()?.bool(forKey: SharedKeys.extendPauseRequested) == true {
                    print("App Group flag triggered: extending pause timer.")
                    self.extendPauseTimer()
                    getSharedDefaults()?.set(false, forKey: SharedKeys.extendPauseRequested)
                }
            }
        }
    }

    func extendPauseTimer() {
        let interval = AppSettings.shared.pauseTimer //always pulled from settings.
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

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        extendPauseFlagTimer?.invalidate()
    }

}
