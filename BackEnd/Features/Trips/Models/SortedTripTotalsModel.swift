import Foundation
import CoreLocation
import Combine

final class SortedTripTotalsModel: ObservableObject {
    let tripType: TripType

    @Published private(set) var totalDistance: CLLocationDistance = 0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var tripCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init(tripType: TripType) {
        self.tripType = tripType

        refreshFromStore()

        SegmentStore.shared.tripTotalsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.refreshFromStore()
            }
            .store(in: &cancellables)
    }

    func refreshFromStore() {
        let type = self.tripType
        DispatchQueue.global(qos: .userInitiated).async {
            let totals = (try? SegmentStore.shared.fetchTotals(type: type)) ?? .empty
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.totalDistance = totals.totalDistanceM
                self.totalDuration = totals.totalDurationS
                self.tripCount = totals.tripCount
            }
        }
    }
}
