import SwiftUI
import Combine

final class TripStatusViewModel: ObservableObject {
    static let shared = TripStatusViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    private let travelStateManager = TravelStateManager.shared
    private let recordingManager = RecordingManager.shared

    @Published var tripStateText: String = ""
    @Published var tripStateColor: Color = .gray
    @Published var tripDistanceCommittedMiles: Double = 0
    @Published var tripDistanceLiveMiles: Double = 0
    @Published var tripState: TravelState = .idle
    @Published var tripDurationCommitted: TimeInterval = 0
    @Published var tripDurationLive: TimeInterval = 0
    @Published var remainingPauseTime: TimeInterval? = nil

    private init() {
        travelStateManager.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.tripState = state
                switch state {
                case .idle:
                    self.tripStateText = "Idle"
                    self.tripStateColor = .gray
                case .traveling:
                    self.tripStateText = "Traveling"
                    self.tripStateColor = .green
                case .paused:
                    self.tripStateText = "Paused"
                    self.tripStateColor = .orange
                }
            }
            .store(in: &cancellables)

        recordingManager.$tripDistanceCommitted
            .removeDuplicates()
            .map { $0 * 0.000621371 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDistanceCommittedMiles, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDistanceLive
            .removeDuplicates()
            .map { $0 * 0.000621371 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDistanceLiveMiles, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDurationCommitted
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDurationCommitted, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDurationLive
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDurationLive, on: self)
            .store(in: &cancellables)
        
        travelStateManager.$pauseRemainingTime
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.remainingPauseTime, on: self)
            .store(in: &cancellables)
    }
}
