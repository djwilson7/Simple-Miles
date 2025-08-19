import Foundation
import CoreLocation
import Combine

final class SortedTripTotalsModel: ObservableObject {

    // MARK: - Identity
    let tripType: TripType
    private var totalsStore: TripTotalsStore

    // MARK: - Published totals (bind these in UI)
    @Published private(set) var totalDistance: CLLocationDistance = 0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var tripCount: Int = 0

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(tripType: TripType) {
        self.tripType = tripType
        self.totalsStore = TripTotalsStore(tripType: tripType)

        // Seed immediately from UserDefaults
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
    /// Reads current totals for this type from UserDefaults via TripTotalsStore and publishes them.
    func refreshFromStore() {
        let d = totalsStore.totalDistance
        let t = totalsStore.totalDuration
        let c = totalsStore.tripCount

        if Thread.isMainThread {
            self.totalDistance = d
            self.totalDuration = t
            self.tripCount = c
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.totalDistance = d
                self.totalDuration = t
                self.tripCount = c
            }
        }
    }
}
