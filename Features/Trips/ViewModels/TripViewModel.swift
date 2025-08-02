import Foundation
import Combine
import CoreLocation

final class TripViewModel: ObservableObject {
    @Published var allSegments: [TripSegment] = []
    @Published var selectedPath: [CLLocationCoordinate2D] = []
    @Published var isReviewing: Bool = false

    private let recordingManager: RecordingManager
    private var cancellables = Set<AnyCancellable>()

    init(recordingManager: RecordingManager) {
        self.recordingManager = recordingManager

        recordingManager.$allSegments
            .receive(on: DispatchQueue.main)
            .assign(to: \.allSegments, on: self)
            .store(in: &cancellables)
    }

    func updateSelectedPath(index: Int) {
        guard allSegments.indices.contains(index) else {
            selectedPath = []
            return
        }
        selectedPath = allSegments[index].pathCoordinates
    }
}
