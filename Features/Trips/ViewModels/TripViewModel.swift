import Foundation
import Combine
import CoreLocation

@MainActor final class TripViewModel: ObservableObject {
    static let shared = TripViewModel()
    
    @Published var unclassifiedSegments: [TripSegment] = []
    @Published var selectedPath: [LocationPoint] = []
    @Published var currentTripIndex: Int = 0

    @Published var tripDistance: String = "0 mi"
    @Published var tripDuration: String = "0s"
    @Published var startDate: String = "Jun 31, 2025"
    @Published var startTime: String = "1:23pm"

    private var cancellables = Set<AnyCancellable>()
    private let tripSegmentStore = TripSegmentStore.shared
    
    private init() {
        self.unclassifiedSegments = tripSegmentStore.loadAllUnclassified()
        
        tripSegmentStore.tripTotalsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.unclassifiedSegments = self?.tripSegmentStore.loadAllUnclassified() ?? []
                self?.updateSelectedPath(index: 0)
            }
            .store(in: &cancellables)
        
        MainStateDriver.shared.$mainState
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                if state == .review, !self.unclassifiedSegments.isEmpty {
                    self.updateSelectedPath(index: 0)
                }
            }
            .store(in: &cancellables)
    }

    
    func updateSelectedPath(index: Int) {
        guard unclassifiedSegments.indices.contains(index) else {
            selectedPath = []
            tripDistance = "0.0 miles"
            tripDuration = "1H 2M 3s"
            startDate = "Jun 01, 2025"
            startTime = "1:23pm"
            return
        }
        currentTripIndex = index
        selectedPath = unclassifiedSegments[index].pathCoordinates
        tripDistance = DistanceUtility.formatter(meters: unclassifiedSegments[index].distance)
        tripDuration = TimeUtility.formatter(unclassifiedSegments[index].duration)
        startDate = TimeUtility.formatDate(unclassifiedSegments[index].startTimestamp)
        startTime = TimeUtility.formatTime(unclassifiedSegments[index].startTimestamp)
    }

    func selectPreviousSegment() {
        if currentTripIndex > 0 {
            currentTripIndex -= 1
            updateSelectedPath(index: currentTripIndex)
        }
    }

    func selectNextSegment() {
        if currentTripIndex + 1 < unclassifiedSegments.count {
            currentTripIndex += 1
            updateSelectedPath(index: currentTripIndex)
        }
    }
    
    func classifyCurrentSegment(newType: TripType) {
        guard unclassifiedSegments.indices.contains(currentTripIndex) else { return }
        var segment = unclassifiedSegments[currentTripIndex]
        tripSegmentStore.delete(segment)
        segment.resortSegment(as: newType)
        tripSegmentStore.write(segment)
        unclassifiedSegments = tripSegmentStore.loadAllUnclassified()
        updateSelectedPath(index: 0)
        
        let allPersonalCount = tripSegmentStore.loadAllPersonal().count
        let allBusinessCount = tripSegmentStore.loadAllBusiness().count
        
        print("Personal Trip Count: \(allPersonalCount)")
        print("Business Trip Count: \(allBusinessCount)")
    }
    
    func resetReviewState() {
        self.selectedPath = []
        self.currentTripIndex = 0
        self.tripDistance = "0.0 miles"
        self.tripDuration = "1H 2M 3s"
        self.startDate = "Jun 31, 2025"
        self.startTime = "1:23pm"
    }
}

