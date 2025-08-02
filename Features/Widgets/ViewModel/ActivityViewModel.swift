import Foundation
import Combine
import ActivityKit
import CoreGraphics

final class ActivityViewModel: ObservableObject {
    // MARK: - UserDefaults Helper
    private let userDefaults = UserDefaults(suiteName: "group.com.simplemiles.shared")
    private func saveToUserDefaults<T>(_ value: T, forKey key: String) {
        userDefaults?.set(value, forKey: key)
    }
    private func saveToUserDefaults(_ value: TimeInterval?, forKey key: String) {
        if let value = value {
            userDefaults?.set(value, forKey: key)
        } else {
            userDefaults?.removeObject(forKey: key)
        }
    }

    // MARK: - Published Outputs
    @Published var tripDistanceCommitted: Double = 0.0 {
        didSet { saveToUserDefaults(tripDistanceCommitted, forKey: "tripDistanceCommitted") }
    }
    @Published var tripDistanceLive: Double = 0.0 {
        didSet { saveToUserDefaults(tripDistanceLive, forKey: "tripDistanceLive") }
    }
    @Published var tripDurationCommitted: TimeInterval = 0 {
        didSet { saveToUserDefaults(tripDurationCommitted, forKey: "tripDurationCommitted") }
    }
    @Published var tripDurationLive: TimeInterval = 0 {
        didSet { saveToUserDefaults(tripDurationLive, forKey: "tripDurationLive") }
    }
    @Published var state: TravelStateManager.TravelState = .idle {
        didSet { saveToUserDefaults(state.displayText, forKey: "state") }
    }
    @Published var sweepProgress: CGFloat = 0 {
        didSet { saveToUserDefaults(Double(sweepProgress), forKey: "sweepProgress") }
    }
    @Published var remainingPauseTime: TimeInterval? = nil {
        didSet { saveToUserDefaults(remainingPauseTime, forKey: "remainingPauseTime") }
    }
    
    // MARK: - Internal
    private var cancellables = Set<AnyCancellable>()
    private let travelStateManager: TravelStateManager
    private let recordingManager: RecordingManager
    private let mapContainerViewModel: MapContainerViewModel
    
    private var currentActivity: Activity<TripActivityAttributes>?
    
    // MARK: - Init
    init(travelStateManager: TravelStateManager, recordingManager: RecordingManager, mapContainerViewModel: MapContainerViewModel) {
        self.travelStateManager = travelStateManager
        self.recordingManager = recordingManager
        self.mapContainerViewModel = mapContainerViewModel
        setupBindings()
        monitorLiveActivityLifecycle()
        launchLiveActivity()
    }
    
    private func setupBindings() {
        recordingManager.$tripDistanceCommitted
            .map { $0 * 0.000621371 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDistanceCommitted)
        
        recordingManager.$tripDistanceLive
            .map { $0 * 0.000621371 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDistanceLive)
        
        recordingManager.$tripDurationCommitted
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDurationCommitted)
        
        recordingManager.$tripDurationLive
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripDurationLive)
        
        travelStateManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
        
        mapContainerViewModel.$remainingPauseTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$remainingPauseTime)
        
        mapContainerViewModel.$sweepProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$sweepProgress)
    }
    
    func monitorLiveActivityLifecycle() {
        $state
            .removeDuplicates()
            .sink { [weak self] newState in
                switch newState {
                case .idle:
                    self?.resetLiveActivityContent()
                case .traveling, .paused:
                    self?.updateLiveActivityContent()
                }
            }
            .store(in: &cancellables)
        
        $tripDistanceCommitted
            .sink { [weak self] _ in self?.updateLiveActivityContent() }
            .store(in: &cancellables)
        
        $tripDistanceLive
            .sink { [weak self] _ in self?.updateLiveActivityContent() }
            .store(in: &cancellables)
        
        $tripDurationCommitted
            .sink { [weak self] _ in self?.updateLiveActivityContent() }
            .store(in: &cancellables)
        
        $tripDurationLive
            .sink { [weak self] _ in self?.updateLiveActivityContent() }
            .store(in: &cancellables)
        
        $sweepProgress
            .sink { [weak self] _ in self?.updateLiveActivityContent() }
            .store(in: &cancellables)
        
        $remainingPauseTime
            .sink { [weak self] _ in self?.updateLiveActivityContent() }
            .store(in: &cancellables)
    }
    
    private func launchLiveActivity() {
        let content = TripActivityAttributes.ContentState(
            tripDistanceCommitted: tripDistanceCommitted,
            tripDistanceLive: tripDistanceLive,
            tripDurationCommitted: tripDurationCommitted,
            tripDurationLive: tripDurationLive,
            state: state.displayText,
            sweepProgress: sweepProgress,
            remainingPauseTime: remainingPauseTime
        )
        
        if let activity = currentActivity {
            Task {
                await activity.update(ActivityContent(state: content, staleDate: nil))
            }
        } else {
            do {
                currentActivity = try Activity<TripActivityAttributes>.request(
                    attributes: TripActivityAttributes(),
                    content: ActivityContent(state: content, staleDate: nil)
                )
            } catch {
                print("[ActivityViewModel] Failed to start Live Activity: \(error)")
            }
        }
    }
    
    //    private func endLiveActivity() {
    //        Task {
    //            await currentActivity?.end(dismissalPolicy: .immediate)
    //            currentActivity = nil
    //        }
    //    }
    
    private func updateLiveActivityContent() {
        guard let activity = currentActivity else { return }
        
        let content = TripActivityAttributes.ContentState(
            tripDistanceCommitted: tripDistanceCommitted,
            tripDistanceLive: tripDistanceLive,
            tripDurationCommitted: tripDurationCommitted,
            tripDurationLive: tripDurationLive,
            state: state.displayText,
            sweepProgress: sweepProgress,
            remainingPauseTime: remainingPauseTime
        )
        
        Task {
            await activity.update(ActivityContent(state: content, staleDate: nil))
        }
    }
    
    private func resetLiveActivityContent() {
        guard let activity = currentActivity else { return }
        let blankContent = TripActivityAttributes.ContentState(
            tripDistanceCommitted: 0,
            tripDistanceLive: 0,
            tripDurationCommitted: 0,
            tripDurationLive: 0,
            state: "",
            sweepProgress: 0,
            remainingPauseTime: nil
        )
        Task {
            await activity.update(ActivityContent(state: blankContent, staleDate: nil))
        }
    }
}
