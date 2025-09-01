import Combine
import Foundation
import SwiftUI

struct PauseTimerSnapshot: Equatable, Identifiable, Codable {
    let id: UUID
    let start: Date
    let end: Date
    let total: TimeInterval
}

@MainActor
final class MainViewModel: ObservableObject {
    @Published var travelState: TravelState = TravelStateManager.shared.state
    @Published var state: MainState = .main
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
                    if let total = self.latestPauseTotal, total > 0 {
                        let start = Date()
                        self.pauseSnapshot = PauseTimerSnapshot(
                            id: UUID(),
                            start: start,
                            end: start.addingTimeInterval(total),
                            total: total
                        )
                    } else {
                        self.pauseSnapshot = nil
                    }
                default:
                    self.pauseSnapshot = nil
                }
            }
            .store(in: &cancellables)

        TravelStateManager.shared.$pauseTotalDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                guard let self = self else { return }
                self.latestPauseTotal = total
                if self.travelState == .paused,
                    let start = self.pauseSnapshot?.start, let total = total,
                    total > 0
                {
                    self.pauseSnapshot = PauseTimerSnapshot(
                        id: UUID(),
                        start: start,
                        end: start.addingTimeInterval(total),
                        total: total
                    )
                }
                self.updateTitle()
            }
            .store(in: &cancellables)

        MainStateManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
                self?.updateTitle()
                self?.isInMainState = (newState == .main)
            }
            .store(in: &cancellables)
    }

    func settingsTapped() {
        MainStateManager.shared.state = .settings
    }

    func extendPauseTapped() {
        TravelStateManager.shared.extendPauseTimer()
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
            if let type = SnapshotViewModel.shared.selectedTripType {
                title = "\(type.name.capitalized) Trips"
            }
        case .summary:
            if let type = SnapshotViewModel.shared.selectedTripType {
                title = "\(type.name.capitalized) Summary"
            }
        }

    }
}
