import Foundation
import Combine
import CoreLocation

final class TripViewModel: ObservableObject {
    @Published var unclassifiedSegments: [TripSegment] = []
    @Published var selectedPath: [CLLocationCoordinate2D] = []
    @Published var isReviewing: Bool = false
    @Published var currentTripIndex: Int = 0

    @Published var currentDistance: String = "0.0 miles"
    @Published var currentDuration: String = "1H 2M 3s"
    @Published var currentStartDate: String = "Jun 31, 2025 1:23pm"

    private var cancellables = Set<AnyCancellable>()
    private let tripSegmentStore = TripSegmentStore.shared
    
    init() {
        TripSegmentStore.shared.uncommitedTripsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.unclassifiedSegments = self?.tripSegmentStore.loadAllUnclassified() ?? []
                self?.updateSelectedPath(index: 0)
            }
            .store(in: &cancellables)
        
        $isReviewing
            .removeDuplicates()
            .sink { [weak self] reviewing in
                guard let self = self else { return }
                unclassifiedSegments = tripSegmentStore.loadAllUnclassified()
                if reviewing, !self.unclassifiedSegments.isEmpty {
                    self.updateSelectedPath(index: 0)
                }
            }
            .store(in: &cancellables)
    }

    func updateSelectedPath(index: Int) {
        guard unclassifiedSegments.indices.contains(index) else {
            selectedPath = []
            currentDistance = "0.0 miles"
            currentDuration = "1H 2M 3s"
            currentStartDate = "Jun 01, 2025 1:23pm"
            return
        }
        currentTripIndex = index
        selectedPath = unclassifiedSegments[index].pathCoordinates
        currentDistance = formatDistance(unclassifiedSegments[index].distance)
        currentDuration = formatDuration(unclassifiedSegments[index].duration)
        currentStartDate = formatDateTime(unclassifiedSegments[index].startTimestamp)
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
    
    func classifyCurrentSegment(newClassification: String) {
        guard unclassifiedSegments.indices.contains(currentTripIndex) else { return }
        var segment = unclassifiedSegments[currentTripIndex]
        tripSegmentStore.delete(segment)
        let newType = TripType(name: newClassification)
        segment.resortSegment(as: newType)
        tripSegmentStore.write(segment)
        unclassifiedSegments = tripSegmentStore.loadAllUnclassified()
        updateSelectedPath(index: 0)
        
        let allPersonalCount = tripSegmentStore.loadAllPersonal().count
        let allBusinessCount = tripSegmentStore.loadAllBusiness().count
        
        print("Personal Trip Count: \(allPersonalCount)")
        print("Business Trip Count: \(allBusinessCount)")
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date).replacingOccurrences(of: ":00pm", with: "pm").replacingOccurrences(of: ":00am", with: "am")
    }
    
    func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.344
        return String(format: "%.1f miles", miles)
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return "\(hours)H \(minutes)M \(secs)s"
        } else if minutes > 0 {
            return "\(minutes)M \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    func resetReviewState() {
        self.selectedPath = []
        self.isReviewing = false
        self.currentTripIndex = 0
        self.currentDistance = "0.0 miles"
        self.currentDuration = "1H 2M 3s"
        self.currentStartDate = "Jun 31, 2025 1:23pm"
    }
}
