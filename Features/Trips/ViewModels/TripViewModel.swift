import Foundation
import Combine
import CoreLocation

@MainActor final class TripViewModel: ObservableObject {
    static let shared = TripViewModel()
    
    @Published var loadedSegments: [TripSegment] = []
    @Published var selectedPath: [LocationPoint] = []
    @Published var currentTripIndex: Int = 0

    @Published var tripDistance: String? = nil
    @Published var tripDuration: String? = nil
    @Published var startDate: String? = nil
    @Published var startTime: String? = nil
    @Published var emptyMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let tripSegmentStore = TripSegmentStore.shared
    
    private init() {
        tripSegmentStore.tripTotalsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                if let t = TripStatusViewModel.shared.reviewTripType {
                    self.loadedSegments = self.tripSegmentStore.loadAll(for: t)
                    if self.loadedSegments.isEmpty {
                        self.setEmptyMessage(tripType: t)
                    } else {
                        self.updateSelectedPath(index: 0)
                    }
                } else {
                    return
                }
            }
            .store(in: &cancellables)

        MainStateDriver.shared.$mainState
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                if state == .review {
                    if let t = TripStatusViewModel.shared.reviewTripType {
                        self.loadedSegments = self.tripSegmentStore.loadAll(for: t)
                        if self.loadedSegments.isEmpty {
                            self.setEmptyMessage(tripType: t)
                        } else {
                            self.updateSelectedPath(index: 0)
                        }
                    } else {
                        return
                    }
                } else {
                    self.resetReviewState()
                }
            }
            .store(in: &cancellables)
    }
    
    func setEmptyMessage(tripType: TripType) {
        emptyMessage = "No \(tripType.name) trips"
        tripDistance = nil
        tripDuration = nil
        startDate = nil
        startTime = nil
        selectedPath = []
    }
    
    func updateSelectedPath(index: Int) {
        emptyMessage = nil
        currentTripIndex = index
        selectedPath = loadedSegments[index].pathCoordinates
        tripDistance = DistanceUtility.formatter(meters: loadedSegments[index].distance)
        tripDuration = TimeUtility.formatter(loadedSegments[index].duration)
        startDate = TimeUtility.formatDate(loadedSegments[index].startTimestamp)
        startTime = TimeUtility.formatTime(loadedSegments[index].startTimestamp)
    }

    func selectPreviousSegment() {
        if currentTripIndex > 0 {
            currentTripIndex -= 1
            updateSelectedPath(index: currentTripIndex)
        }
    }

    func selectNextSegment() {
        if currentTripIndex + 1 < loadedSegments.count {
            currentTripIndex += 1
            updateSelectedPath(index: currentTripIndex)
        }
    }
    
    func classifyCurrentSegment(newType: TripType) {
        guard loadedSegments.indices.contains(currentTripIndex) else { return }
        var segment = loadedSegments[currentTripIndex]
        tripSegmentStore.delete(segment)
        segment.resortSegment(as: newType)
        tripSegmentStore.write(segment)
    }
    
    func resetReviewState() {
        self.selectedPath = []
        self.currentTripIndex = 0
        self.tripDistance = nil
        self.tripDuration = nil
        self.startDate = nil
        self.startTime = nil
        self.emptyMessage = nil
    }
}

