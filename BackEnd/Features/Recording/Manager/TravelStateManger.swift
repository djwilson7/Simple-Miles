import SwiftUI
import Foundation
import Combine
import CoreLocation
import CoreML
import NotificationCenter


@MainActor
final class TravelStateManager: ObservableObject {
    static let shared = TravelStateManager()
    
    @Published var pauseRemainingTime: TimeInterval? = nil
    @Published private(set) var state: TravelState = .idle
    @Published private(set) var pauseTotalDuration: TimeInterval? = nil

    private var pauseTimer: Timer?
    private var extendPauseFlagTimer: Timer?
    private var notificationObserver: NSObjectProtocol?
    private var drivingStateCancellable: AnyCancellable?
    private let locationManager = LocationManager.shared
    private let drivingStateManager = DrivingStateManager.shared
    private let settings = SettingsManager.shared

    private init() {
        pauseRemainingTime = nil
        pauseTotalDuration = nil
        subscribeToDrivingState()
    }

    func extendPauseTimer() {
        let interval = settings.pauseTimer
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

    private func subscribeToDrivingState() {
        drivingStateCancellable = drivingStateManager.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDriving in
                self?.handleDrivingStateChange(isDriving)
            }
    }

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
        pauseRemainingTime = settings.pauseTimer
        pauseTotalDuration = settings.pauseTimer
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
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        extendPauseFlagTimer?.invalidate()
    }

}
