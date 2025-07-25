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

    var onShare: (() -> Void)?
    var onSettings: (() -> Void)?
    var onSummary: (() -> Void)?
    
    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()
    private let recordingManager: RecordingManager
    private let travelStateManager: TravelStateManager
    private let cameraManager: CameraManager

    // MARK: - Private Properties

    private var pauseStartUptime: TimeInterval?

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
    init(recordingManager: RecordingManager, travelStateManager: TravelStateManager, cameraManager: CameraManager) {
        self.recordingManager = recordingManager
        self.travelStateManager = travelStateManager
        self.cameraManager = cameraManager
        setupBindings()
        startSweepLoop()
    }

    // MARK: - State Binding

    private func setupBindings() {
        travelStateManager.$state
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] state in
                if state == .paused {
                    self?.pauseStartUptime = ProcessInfo.processInfo.systemUptime
                }
            })
            .assign(to: &$tripState)


        recordingManager.$tripDistance
            .receive(on: DispatchQueue.main)
            .map { String(format: "%.1f miles", $0 * 0.000621371) }
            .assign(to: &$tripDistance)

        recordingManager.$tripDuration
            .receive(on: DispatchQueue.main)
            .map {
                let minutes = Int($0) / 60
                let seconds = Int($0) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
            .assign(to: &$tripDuration)

        travelStateManager.$pauseRemainingTime
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$remainingPauseTime)

        travelStateManager.$pauseTotalDuration
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$totalPauseTime)
    }

    // MARK: - Sweep Progress (Looping Clock-Face)

    private func startSweepLoop() {
        Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self,
                      self.tripState == .paused,
                      let total = self.totalPauseTime,
                      let pauseStart = self.pauseStartUptime else {
                    self?.sweepProgress = 0
                    return
                }

                let elapsed = ProcessInfo.processInfo.systemUptime - pauseStart
                self.sweepProgress = min(CGFloat(elapsed / total), 1.0)
            }
            .store(in: &cancellables)
    }

    // MARK: - Button Events

    func recenterTapped() {
        let currentMode = cameraManager.orientationMode
        cameraManager.setOrientationMode(currentMode)
    }
    
    func shareTapped()    {
        onShare?()
    }
    
    func settingsTapped() {
        onSettings?()
    }
    
    func summaryTapped()  {
        onSummary?()
    }

    func extendPauseTapped() {
        travelStateManager.extendPauseTimer()
    }
}
