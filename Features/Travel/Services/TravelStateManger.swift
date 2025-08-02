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
                self.state = .idle
                print("TravelState Transitioned: .idle (pause timer expired)")
            } else {
                self.pauseRemainingTime = remaining - 1
            }
        }
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

}
