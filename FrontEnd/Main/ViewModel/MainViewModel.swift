import Combine
import Foundation
import SwiftUI

/// Orchestrates high-level main UI state for MainView:
/// - Mirrors app state (MainState, TravelState)
/// - Manages pause timer snapshot
/// - Provides simple user intents for navigation/actions
@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Published State (UI)
    @Published private(set) var travelState: TravelState = TravelStateManager.shared.state
    @Published private(set) var state: MainStateManager.MainState = .main
    @Published private(set) var title: String = "Simple Miles"
    @Published private(set) var isInMainState: Bool = true

    /// When paused, captures start/end/total for the countdown display.
    @Published private(set) var pauseSnapshot: PauseTimerSnapshot? = nil

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var latestPauseTotal: TimeInterval? = nil

    // MARK: - Init
    init() {
        bind()
    }

    // MARK: - Bindings
    private func bind() {
        // Travel state -> mirror state, manage pause snapshot, update title
        TravelStateManager.shared.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                self.travelState = newState
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
                self.updateTitle()
            }
            .store(in: &cancellables)

        // Pause total duration -> keep latest, update snapshot if still paused, update title
        TravelStateManager.shared.$pauseTotalDuration
            .removeDuplicates { $0 == $1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                guard let self else { return }
                self.latestPauseTotal = total
                if self.travelState == .paused,
                    let start = self.pauseSnapshot?.start,
                    let total = total,
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

        // Main state -> mirror, update title, expose convenience boolean
        MainStateManager.shared.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                self.state = newState
                self.isInMainState = (newState == .main)
                self.updateTitle()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API (User Intents)
    func settingsTapped() {
        MainStateManager.shared.state = .settings
    }

    func extendPauseTapped() {
        TravelStateManager.shared.extendPauseTimer()
    }

    // MARK: - Private Helpers
    private func updateTitle() {
        switch state {
        case .main:
            if travelState == .paused, let snap = pauseSnapshot {
                let remaining = max(0, snap.end.timeIntervalSinceNow)
                title = TimeUtility.formatter(remaining)
            } else {
                title = "Simple Miles"
            }

        case .settings:
            title = "Settings"

        case .review:
            if let type = SnapshotViewModel.shared.selectedTripType {
                title = "\(type.name.capitalized) Trips"
            } else {
                title = "Trips"
            }

        case .summary:
            if let type = SnapshotViewModel.shared.selectedTripType {
                title = "\(type.name.capitalized) Summary"
            } else {
                title = "Summary"
            }
        }
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - Types
struct PauseTimerSnapshot: Equatable, Identifiable, Codable {
    let id: UUID
    let start: Date
    let end: Date
    let total: TimeInterval
}
