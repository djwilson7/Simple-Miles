import Foundation
import Combine
import CoreGraphics

class TBViewModel: ObservableObject {
    @Published var travelState: TravelState = TravelStateManager.shared.state
    @Published var state: MainModes = MainStateDriver.shared.mainState
    @Published var title: String = "Simple Miles"
    @Published var isInMainState: Bool = true
    @Published var sweepProgress: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()
    private var pauseRemainingTime: TimeInterval? = nil
    private var totalPauseDuration: TimeInterval? = nil

    init() {
        TravelStateManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.travelState = newState
                self?.updateTitle()
            }
            .store(in: &cancellables)
        
        TravelStateManager.shared.$pauseRemainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                self?.pauseRemainingTime = remaining
                self?.updateSweepProgress()
                self?.updateTitle()
            }
            .store(in: &cancellables)
        
        TravelStateManager.shared.$pauseTotalDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                self?.totalPauseDuration = total
                self?.updateSweepProgress()
                self?.updateTitle()
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
            if travelState == .paused {
                title = "\(TimeUtility.formatter(pauseRemainingTime ?? 0))"
            } else {
                title = "Simple Miles"
            }
        case .settings:
            title = "Settings"
        case .review:
            title = "Trip Sorting"
        }
    }
    
    

    private func updateSweepProgress() {
        if let remaining = pauseRemainingTime,
           let total = totalPauseDuration,
           total > 0 {
            sweepProgress = CGFloat(1 - (remaining / total))
        } else {
            sweepProgress = 0
        }
    }

    func backButtonPressed() {
        MainStateDriver.shared.mainState = .main // when we tap back button we set main state back to main
    }

    func extendPauseButtonPressed() {
        TravelStateManager.shared.extendPauseTimer()
    }
}

