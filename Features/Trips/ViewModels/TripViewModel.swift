import Foundation
import Combine
import CoreLocation

final class TripViewModel: ObservableObject {
    @Published var allSegments: [TripSegment] = []
    @Published var selectedPath: [CLLocationCoordinate2D] = []
    @Published var isReviewing: Bool = false
    @Published var currentTripIndex: Int = 0

    @Published var currentDistance: String = "0.0 miles"
    @Published var currentDuration: String = "1H 2M 3s"
    @Published var currentStartDate: String = "Jun 31, 2025 1:23pm"

    private let recordingManager: RecordingManager
    private var cancellables = Set<AnyCancellable>()

    init(recordingManager: RecordingManager) {
        self.recordingManager = recordingManager

        recordingManager.$allSegments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] segments in
                self?.allSegments = segments
                if !segments.isEmpty {
                    self?.updateSelectedPath(index: 0)
                }
            }
            .store(in: &cancellables)
        
        $isReviewing
            .removeDuplicates()
            .sink { [weak self] reviewing in
                guard let self = self else { return }
                if reviewing, !self.allSegments.isEmpty {
                    self.updateSelectedPath(index: 0)
                }
            }
            .store(in: &cancellables)
    }

    func updateSelectedPath(index: Int) {
        guard allSegments.indices.contains(index) else {
            selectedPath = []
            currentDistance = "0.0 miles"
            currentDuration = "1H 2M 3s"
            currentStartDate = "Jun 01, 2025 1:23pm"
            return
        }
        currentTripIndex = index
        selectedPath = allSegments[index].pathCoordinates
        currentDistance = formatDistance(allSegments[index].distance)
        currentDuration = formatDuration(allSegments[index].duration)
        currentStartDate = formatDateTime(allSegments[index].startTimestamp)
    }

    func selectPreviousSegment() {
        if currentTripIndex > 0 {
            currentTripIndex -= 1
            updateSelectedPath(index: currentTripIndex)
        }
    }

    func selectNextSegment() {
        if currentTripIndex + 1 < allSegments.count {
            currentTripIndex += 1
            updateSelectedPath(index: currentTripIndex)
        }
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
