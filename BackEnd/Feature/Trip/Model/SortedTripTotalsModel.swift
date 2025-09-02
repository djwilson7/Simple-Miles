import Foundation
import CoreLocation
import Combine

/// Observable model that exposes aggregated totals for a specific TripType.
/// Totals are sourced from SegmentStore and kept up to date via a publisher.
final class SortedTripTotalsModel: ObservableObject {

    // MARK: - Identity
    let tripType: TripType

    // MARK: - Published State
    @Published private(set) var totalDistance: CLLocationDistance = 0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var tripCount: Int = 0

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
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

    // MARK: - Domain Methods
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
