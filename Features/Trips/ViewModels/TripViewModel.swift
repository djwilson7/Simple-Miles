import Foundation
import Combine
import CoreLocation

@MainActor final class TripViewModel: ObservableObject {
    static let shared = TripViewModel()
    
    @Published var loadedSegments: [TripMeta] = []
    @Published var selectedPath: [CLLocationCoordinate2D] = []
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
                    self.loadedSegments = self.tripSegmentStore.fetchInitial(for: t, limit: 50)
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
                        self.loadedSegments = self.tripSegmentStore.fetchInitial(for: t, limit: 50)
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
        selectedPath = [] // CLLocationCoordinate2D
    }
    
    func updateSelectedPath(index: Int) {
        emptyMessage = nil
        currentTripIndex = index
        let meta = loadedSegments[index]
        selectedPath = tripSegmentStore.fetchDisplayPath(for: meta.id)
        tripDistance = DistanceUtility.formatter(meters: meta.distanceM)
        tripDuration = TimeUtility.formatter(meta.durationS)
        let start = meta.startDate
        startDate = TimeUtility.formatDate(start)
        startTime = TimeUtility.formatTime(start)
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
        let meta = loadedSegments[currentTripIndex]
        let tripID = meta.id

        // Kick off DB change (it dispatches to a background queue internally)
        tripSegmentStore.reclassify(tripID: tripID, to: newType)

        // Decide if it should stay visible on this page
        if let reviewType = TripStatusViewModel.shared.reviewTripType, reviewType != newType {
            // Remove from current list and adjust selection
            loadedSegments.remove(at: currentTripIndex)
            if loadedSegments.isEmpty {
                setEmptyMessage(tripType: reviewType)
            } else {
                let newIndex = min(currentTripIndex, loadedSegments.count - 1)
                updateSelectedPath(index: newIndex)
            }
        } else {
            // Same page; just refresh visible stats/path
            updateSelectedPath(index: currentTripIndex)
        }
    }
    
    func resetReviewState() {
        self.selectedPath = [] // CLLocationCoordinate2D
        self.currentTripIndex = 0
        self.tripDistance = nil
        self.tripDuration = nil
        self.startDate = nil
        self.startTime = nil
        self.emptyMessage = nil
    }
}

