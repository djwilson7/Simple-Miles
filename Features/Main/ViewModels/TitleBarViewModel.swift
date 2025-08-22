import Foundation
import Combine
import CoreGraphics

struct PauseTimerSnapshot: Equatable, Identifiable, Codable {
    let id: UUID
    let start: Date
    let end: Date
    let total: TimeInterval
}

@MainActor
class TBViewModel: ObservableObject {
    @Published var travelState: TravelState = TravelStateManager.shared.state
    @Published var state: MainModes = .main
    @Published var title: String = "Simple Miles"
    @Published var isInMainState: Bool = true
    @Published var pauseSnapshot: PauseTimerSnapshot? = nil

    private var cancellables = Set<AnyCancellable>()
    private var latestPauseTotal: TimeInterval? = nil

    init() {
        TravelStateManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.travelState = newState
                self?.updateTitle()
                guard let self = self else { return }
                switch newState {
                case .paused:
                    // Build a fresh snapshot from now using the latest known total
                    if let total = self.latestPauseTotal, total > 0 {
                        let start = Date()
                        self.pauseSnapshot = PauseTimerSnapshot(id: UUID(), start: start, end: start.addingTimeInterval(total), total: total)
                    } else {
                        self.pauseSnapshot = nil
                    }
                default:
                    // Leaving paused: clear snapshot
                    self.pauseSnapshot = nil
                }
            }
            .store(in: &cancellables)
        
        TravelStateManager.shared.$pauseTotalDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                guard let self = self else { return }
                self.latestPauseTotal = total
                // If we are currently paused and have a snapshot, extend by pushing end forward (keep start constant)
                if self.travelState == .paused, let start = self.pauseSnapshot?.start, let total = total, total > 0 {
                    self.pauseSnapshot = PauseTimerSnapshot(id: UUID(), start: start, end: start.addingTimeInterval(total), total: total)
                }
                self.updateTitle()
            }
            .store(in: &cancellables)

        MainStateDriver.shared.$mainState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
                self?.updateTitle()
                self?.isInMainState = (newState == .main)
            }
            .store(in: &cancellables)
    }

    private func updateTitle() {
        switch state {
        case .main:
            if travelState == .paused, let snap = pauseSnapshot {
                let remaining = max(0, snap.end.timeIntervalSinceNow)
                title = "\(TimeUtility.formatter(remaining))"
            } else {
                title = "Simple Miles"
            }
        case .settings:
            title = "Settings"
        case .review:
            if let type = TripStatusViewModel.shared.reviewTripType {
                title = "\(type.name.capitalized) Trips"
            }
        }
    }

    func backButtonPressed() {
        MainStateDriver.shared.mainState = .main // when we tap back button we set main state back to main
    }

    func extendPauseButtonPressed() {
        TravelStateManager.shared.extendPauseTimer()
    }
}
