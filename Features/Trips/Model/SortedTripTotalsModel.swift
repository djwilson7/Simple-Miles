import Foundation
import CoreLocation
import Combine

final class SortedTripTotalsModel: ObservableObject {

    // MARK: - Identity
    let tripType: TripType

    // MARK: - Published totals (bind these in UI) — now backed by SQLite aggregates
    @Published private(set) var totalDistance: CLLocationDistance = 0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var tripCount: Int = 0

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(tripType: TripType) {
        self.tripType = tripType

        // Seed immediately from SQLite
        refreshFromStore()

        // Refresh on any totals recompute from the store
        TripSegmentStore.shared.tripTotalsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.refreshFromStore()
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh
    /// Reads current totals for this type from SQLite and publishes them.
    func refreshFromStore() {
        let type = self.tripType
        DispatchQueue.global(qos: .userInitiated).async {
            let totals = (try? TripSegmentStore.shared.fetchTotals(type: type)) ?? .empty
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.totalDistance = totals.totalDistanceM
                self.totalDuration = totals.totalDurationS
                self.tripCount = totals.tripCount
            }
        }
    }
}
