import Foundation
import Combine
import SwiftUI

final class MapContainerViewModel: ObservableObject {
    // MARK: - Published UI Bindings

    @Published var tripState: TravelState = .idle
    @Published var tripDistanceLiveMiles: Double = 0.0
    @Published var tripDistanceCommittedMiles: Double = 0.0
    @Published var tripDurationLive: TimeInterval = 0
    @Published var tripDurationCommitted: TimeInterval = 0
    @Published var remainingPauseTime: TimeInterval? = nil
    @Published var sweepProgress: CGFloat = 0
    @Published var totalPauseTime: TimeInterval? = nil
    let tripViewModel: TripViewModel

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

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds) seconds"
        }
    }

    // MARK: - Init
    init(recordingManager: RecordingManager, travelStateManager: TravelStateManager, cameraManager: CameraManager, tripViewModel: TripViewModel) {
        self.recordingManager = recordingManager
        self.travelStateManager = travelStateManager
        self.cameraManager = cameraManager
        self.tripViewModel = tripViewModel
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


        recordingManager.$tripDistanceLive
            .map { $0 * 0.000621371 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDistanceLiveMiles)

        recordingManager.$tripDistanceCommitted
            .map { $0 * 0.000621371 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDistanceCommittedMiles)

        recordingManager.$tripDurationLive
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDurationLive)

        recordingManager.$tripDurationCommitted
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDurationCommitted)

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
