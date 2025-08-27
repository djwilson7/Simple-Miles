import Foundation
import Combine
import CoreLocation

@MainActor final class TripViewModel: ObservableObject {
    static let shared = TripViewModel()
    
    @Published var tripCount: Int = 0                // total trips for current review type
    @Published var selectedPath: [CLLocationCoordinate2D] = []
    @Published var currentTripIndex: Int = 0

    // Paged IDs cache: pageIndex -> [tripID]
    private var idPages: [Int: [String]] = [:]

    @Published var tripDistance: String? = nil
    @Published var tripDuration: String? = nil
    @Published var startDate: String? = nil
    @Published var startTime: String? = nil
    @Published var emptyMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let tripSegmentStore = TripSegmentStore.shared
    private let pageSize: Int = 10
    
    private init() {
        tripSegmentStore.tripTotalsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                if let t = TripStatusViewModel.shared.selectedTripType {
                    let oldIndex = self.currentTripIndex
                    let total = (try? self.tripSegmentStore.count(type: t)) ?? 0
                    self.tripCount = total
                    self.idPages.removeAll()
                    if total == 0 {
                        self.currentTripIndex = 0
                        self.setEmptyMessage(tripType: t)
                    } else {
                        // Preserve current index when possible; clamp to last item if needed
                        let preserved = min(max(0, oldIndex), total - 1)
                        self.currentTripIndex = preserved
                        let page = preserved / self.pageSize
                        self.ensurePageLoaded(page, for: t)
                        self.updateSelectedPath(index: preserved)
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
                    if let t = TripStatusViewModel.shared.selectedTripType {
                        let total = (try? self.tripSegmentStore.count(type: t)) ?? 0
                        self.tripCount = total
                        self.currentTripIndex = 0
                        self.idPages.removeAll()
                        if total == 0 {
                            self.setEmptyMessage(tripType: t)
                        } else {
                            self.ensurePageLoaded(0, for: t)
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
    
    /// Ensure a specific page of IDs is loaded into the cache.
    private func ensurePageLoaded(_ pageIndex: Int, for type: TripType) {
        if idPages[pageIndex] != nil { return }

        var afterTs: Int64? = nil
        if pageIndex > 0 {
            // Ensure previous page exists to derive the cursor
            ensurePageLoaded(pageIndex - 1, for: type)
            guard let prevIDs = idPages[pageIndex - 1],
                  let lastID = prevIDs.last,
                  let lastMeta = try? tripSegmentStore.fetchMeta(id: lastID) else { return }
            afterTs = lastMeta.startTs
        }
        let ids = tripSegmentStore.fetchTripIDPage(for: type, afterTs: afterTs, limit: pageSize)
        idPages[pageIndex] = ids
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
        guard let reviewType = TripStatusViewModel.shared.selectedTripType else { return }
        guard index >= 0, index < tripCount else { return }
        emptyMessage = nil
        currentTripIndex = index

        let page = index / pageSize
        let inner = index % pageSize
        ensurePageLoaded(page, for: reviewType)
        guard let pageIDs = idPages[page], inner < pageIDs.count else { return }
        let tripID = pageIDs[inner]

        let tripSegmentStore = self.tripSegmentStore
        Task {
            async let metaTask: TripMeta? = { try? tripSegmentStore.fetchMeta(id: tripID) }()
            async let pathTask: [CLLocationCoordinate2D] = { tripSegmentStore.fetchDisplayPath(for: tripID) }()
            let meta = await metaTask
            let path = await pathTask
            await MainActor.run {
                self.selectedPath = path
                if let meta = meta {
                    self.tripDistance = DistanceUtility.formatter(meters: meta.distanceM)
                    self.tripDuration = TimeUtility.formatter(meta.durationS)
                    let start = meta.startDate
                    self.startDate = TimeUtility.formatDate(start)
                    self.startTime = TimeUtility.formatTime(start)
                } else {
                    self.tripDistance = nil
                    self.tripDuration = nil
                    self.startDate = nil
                    self.startTime = nil
                }
            }
        }
    }

    func selectPreviousSegment() {
        if currentTripIndex > 0 { updateSelectedPath(index: currentTripIndex - 1) }
    }

    func selectNextSegment() {
        if currentTripIndex + 1 < tripCount { updateSelectedPath(index: currentTripIndex + 1) }
    }
    
    func classifyCurrentSegment(newType: TripType) {
        guard let reviewType = TripStatusViewModel.shared.selectedTripType else { return }
        guard currentTripIndex >= 0, currentTripIndex < tripCount else { return }
        let page = currentTripIndex / pageSize
        let inner = currentTripIndex % pageSize
        ensurePageLoaded(page, for: reviewType)
        guard let pageIDs = idPages[page], inner < pageIDs.count else { return }
        let tripID = pageIDs[inner]

        // No-op if type is unchanged
        if let meta = try? tripSegmentStore.fetchMeta(id: tripID), meta.type == newType.dbValue {
            return
        }

        // Kick off DB change
        tripSegmentStore.reclassify(tripID: tripID, to: newType)

        // Refresh count for the current review type, then decide the next index.
        let newTotal = (try? tripSegmentStore.count(type: reviewType)) ?? max(0, tripCount - 1)
        tripCount = newTotal
        idPages.removeAll() // force fresh paging so removed item doesn't linger

        if newTotal == 0 {
            setEmptyMessage(tripType: reviewType)
            return
        }

        // If we removed the last item, clamp to the new last index; otherwise stay at the same index (next item slides into this slot).
        let nextIndex = min(currentTripIndex, newTotal - 1)
        updateSelectedPath(index: nextIndex)
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
