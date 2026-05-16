import SwiftUI
import Combine

// MARK: - Supporting Types
struct StatusBlock: Identifiable, Equatable {
    enum Role: Equatable { case value, status }
    let id: String
    let primary: String
    let secondary: String?
    let role: Role
    init(id: String, primary: String, secondary: String? = nil, role: Role = .value) {
        self.id = id
        self.primary = primary
        self.secondary = secondary
        self.role = role
    }
}

struct StatusPage: Identifiable, Equatable {
    let id: String
    let left: StatusBlock
    let center: StatusBlock
    let right: StatusBlock
    let tripType: TripType?
}

// MARK: - ViewModel
/// Aggregates live trip status and category totals for SnapshotView.
/// Subscribes to travel/recording managers and exposes UI-friendly state and pages.
@MainActor
final class SnapshotViewModel: ObservableObject {

    // MARK: - Singleton
    static let shared = SnapshotViewModel()

    // MARK: - Dependencies
    private let travelStateManager = TravelStateManager.shared
    private let recordingManager = RecordingManager.shared

    // MARK: - Published State (UI)
    @Published private(set) var tripStateText: String = ""
    @Published private(set) var tripStateColor: Color = .gray

    @Published private(set) var tripDistanceCommitted: Double = 0
    @Published private(set) var tripDistanceLive: Double = 0

    @Published private(set) var tripState: TravelState = .idle
    @Published private(set) var tripDurationCommitted: TimeInterval = 0
    @Published private(set) var tripDurationLive: TimeInterval = 0
    @Published private(set) var remainingPauseTime: TimeInterval? = nil

    /// Bound by the SnapshotView's TabView and indicators; must remain writable.
    @Published var currentPageIndex: Int = 0

    /// Selected trip type (drives "Review" and "Summary" actions in MainView).
    @Published private(set) var selectedTripType: TripType? = nil

    /// Returns the trip count for the currently selected category.
    var selectedCategoryTripCount: Int {
        guard let type = selectedTripType else { return 0 }
        switch type {
        case .personal: return personalTrips.tripCount
        case .business: return businessTrips.tripCount
        case .custom: return customTrips.tripCount
        case .unsorted: return unclassifiedTrips.tripCount
        case .trash: return trashTrips.tripCount
        }
    }

    /// Totals models for each category (observed by views).
    @Published private(set) var personalTrips = SortedTripTotalsModel(tripType: .personal)
    @Published private(set) var businessTrips = SortedTripTotalsModel(tripType: .business)
    @Published private(set) var customTrips = SortedTripTotalsModel(tripType: .custom)
    @Published private(set) var unclassifiedTrips = SortedTripTotalsModel(tripType: .unsorted)
    @Published private(set) var trashTrips = SortedTripTotalsModel(tripType: .trash)

    // MARK: - Computed (UI-derived)
    var pages: [StatusPage] { makeStatusPages() }

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        bind()

        // Initial sync so selection reflects the initial page.
        syncSelectionToCurrentPage()
    }

    // MARK: - Bindings
    private func bind() {
        travelStateManager.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.tripState = state
                switch state {
                case .idle:
                    self.tripStateText = "Idle"
                    self.tripStateColor = .gray
                case .traveling:
                    self.tripStateText = "Traveling"
                    self.tripStateColor = .green
                case .paused:
                    self.tripStateText = "Paused"
                    self.tripStateColor = .orange
                }
            }
            .store(in: &cancellables)

        recordingManager.$tripDistanceCommitted
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDistanceCommitted, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDistanceLive
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDistanceLive, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDurationCommitted
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDurationCommitted, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDurationLive
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDurationLive, on: self)
            .store(in: &cancellables)

        travelStateManager.$pauseRemainingTime
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.remainingPauseTime, on: self)
            .store(in: &cancellables)

        $currentPageIndex
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncSelectionToCurrentPage()
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    private func makeStatusPages() -> [StatusPage] {
        let homeLeft = StatusBlock(
            id: "home.distance",
            primary: DistanceUtility.formatter(meters: tripDistanceLive),
            secondary: tripDistanceCommitted > 0 ? DistanceUtility.formatter(meters: tripDistanceCommitted) : nil,
            role: .value
        )
        let homeCenter = StatusBlock(
            id: "home.state",
            primary: tripStateText,
            secondary: nil,
            role: .status
        )
        let homeRight = StatusBlock(
            id: "home.time",
            primary: TimeUtility.formatDuration(tripDurationLive),
            secondary: tripDurationCommitted > 0 ? TimeUtility.formatDuration(tripDurationCommitted) : nil,
            role: .value
        )
        var result: [StatusPage] = [
            StatusPage(id: "page.home", left: homeLeft, center: homeCenter, right: homeRight, tripType: nil)
        ]

        func totalsPage(model: SortedTripTotalsModel) -> StatusPage {
            let left = StatusBlock(
                id: "\(model.tripType.name.capitalized).distance",
                primary: DistanceUtility.formatter(meters: model.totalDistance),
                secondary: nil,
                role: .value
            )
            let tripCountText: String
            if model.tripCount == 0 {
                tripCountText = "No trips"
            } else if model.tripCount == 1 {
                tripCountText = "1 trip"
            } else {
                tripCountText = "\(model.tripCount) trips"
            }

            let center = StatusBlock(
                id: "\(model.tripType.name.capitalized).count",
                primary: model.tripType.name.capitalized,
                secondary: tripCountText,
                role: .status
            )
            let right = StatusBlock(
                id: "\(model.tripType.name.capitalized).duration",
                primary: TimeUtility.formatDuration(model.totalDuration),
                secondary: nil,
                role: .value
            )
            return StatusPage(
                id: "page.\(model.tripType.name.capitalized)",
                left: left, center: center, right: right,
                tripType: model.tripType
            )
        }

        result.append(totalsPage(model: personalTrips))
        result.append(totalsPage(model: businessTrips))
        result.append(totalsPage(model: customTrips))
        result.append(totalsPage(model: unclassifiedTrips))
        result.append(totalsPage(model: trashTrips))

        return result
    }

    /// Sync selectedTripType with the page at currentPageIndex.
    private func syncSelectionToCurrentPage() {
        let index = currentPageIndex
        let allPages = pages
        guard index >= 0, index < allPages.count else {
            selectedTripType = nil
            return
        }
        let page = allPages[index]
        selectedTripType = page.tripType // nil for live status page
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
