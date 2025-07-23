import Foundation
import Combine
import SwiftUI

final class MapContainerViewModel: ObservableObject {
    // MARK: - Published UI Bindings

    @Published var tripState: TravelStateManager.TravelState = .idle
    @Published var tripDistance: String = "0.0 miles"
    @Published var tripDuration: String = "0m"
    @Published var remainingPauseTime: TimeInterval? = nil
    @Published var sweepProgress: CGFloat = 0
    @Published var totalPauseTime: TimeInterval? = nil

    // MARK: - Action Hooks

    var onRecenter: (() -> Void)?
    var onShare: (() -> Void)?
    var onSettings: (() -> Void)?
    var onSummary: (() -> Void)?
    
    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()
    private let recordingManager: RecordingManager
    private let travelStateManager: TravelStateManager

    // MARK: - Computed Bindings

    var tripStateText: String {
        tripState.displayText
    }

    var tripStateColor: Color {
        tripState.color
    }

    var pauseCountdownFormatted: String {
        guard let remaining = remainingPauseTime else { return "" }
        return String(format: "%d:%02d", Int(remaining) / 60, Int(remaining) % 60)
    }

    // MARK: - Init
    init(recordingManager: RecordingManager, travelStateManager: TravelStateManager) {
        print("[MapContainerViewModel] (init) - Initializing and setting up bindings and sweep loop")
        self.recordingManager = recordingManager
        self.travelStateManager = travelStateManager
        setupBindings()
        startSweepLoop()
    }

    // MARK: - State Binding

    private func setupBindings() {
        print("[MapContainerViewModel] (setupBindings) - Binding travel state, trip distance, duration, and pause timer")
        travelStateManager.$state
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { _ in
                print("[MapContainerViewModel] (setupBindings) - Received updated value for tripState")
            })
            .assign(to: &$tripState)


        recordingManager.$tripDistance
            .receive(on: DispatchQueue.main)
            .map { String(format: "%.1f miles", $0 * 0.000621371) }
            .handleEvents(receiveOutput: { _ in
                print("[MapContainerViewModel] (setupBindings) - Received updated value for tripDistance")
            })
            .assign(to: &$tripDistance)

        recordingManager.$tripDuration
            .receive(on: DispatchQueue.main)
            .map { "\(Int($0 / 60))m" }
            .handleEvents(receiveOutput: { _ in
                print("[MapContainerViewModel] (setupBindings) - Received updated value for tripDuration")
            })
            .assign(to: &$tripDuration)

        travelStateManager.$pauseTimerInterval
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { _ in
                print("[MapContainerViewModel] (setupBindings) - Received updated value for remainingPauseTime")
            })
            .assign(to: &$remainingPauseTime)
        
        travelStateManager.$totalPauseTimerDuration
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$totalPauseTime)
    }

    // MARK: - Sweep Progress (Looping Clock-Face)

    private func startSweepLoop() {
        print("[MapContainerViewModel] (startSweepLoop) - Starting sweep loop for pause countdown visualization")
        Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self,
                      self.tripState == .paused,
                      let total = self.totalPauseTime,
                      let remaining = self.remainingPauseTime,
                      total > 0 else {
                    return
                }

                self.sweepProgress = CGFloat(1.0 - (remaining / total))
            }
            .store(in: &cancellables)
    }

    // MARK: - Button Events

    func recenterTapped() {
        print("[MapContainerViewModel] (recenterTapped) - Recenter button tapped")
        onRecenter?()
    }
    func shareTapped()    {
        print("[MapContainerViewModel] (shareTapped) - Share button tapped")
        onShare?()
    }
    func settingsTapped() {
        print("[MapContainerViewModel] (settingsTapped) - Settings button tapped")
        onSettings?()
    }
    func summaryTapped()  {
        print("[MapContainerViewModel] (summaryTapped) - Summary button tapped")
        onSummary?()
    }
}
