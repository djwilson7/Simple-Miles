
import SwiftUI
import Combine

// MARK: - View Data for Trip Status pages
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

final class TripStatusViewModel: ObservableObject {
    static let shared = TripStatusViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    private let travelStateManager = TravelStateManager.shared
    private let recordingManager = RecordingManager.shared

    @Published var tripStateText: String = ""
    @Published var tripStateColor: Color = .gray
    @Published var tripDistanceCommittedMiles: Double = 0
    @Published var tripDistanceLiveMiles: Double = 0
    @Published var tripState: TravelState = .idle
    @Published var tripDurationCommitted: TimeInterval = 0
    @Published var tripDurationLive: TimeInterval = 0
    @Published var remainingPauseTime: TimeInterval? = nil

    @Published var currentPageIndex: Int = 0

    var reviewTripType: TripType? = nil

    @Published var personalTrips = SortedTripTotalsModel(tripType: .personal)
    @Published var businessTrips = SortedTripTotalsModel(tripType: .business)
    @Published var customTrips = SortedTripTotalsModel(tripType: .custom)
    @Published var unclassifiedTrips = SortedTripTotalsModel(tripType: .unclassified)
    
    private init() {
        travelStateManager.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
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
            .assign(to: \.tripDistanceCommittedMiles, on: self)
            .store(in: &cancellables)

        recordingManager.$tripDistanceLive
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tripDistanceLiveMiles, on: self)
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
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.remainingPauseTime, on: self)
            .store(in: &cancellables)
    }
    
    @MainActor func beginReview(for type: TripType) {
        reviewTripType = type
        MainStateDriver.shared.mainState = .review
    }

    func clearReviewRequest() { reviewTripType = nil }
    
    // MARK: - Swipeable pages for TripStatusView
    var pages: [StatusPage] { makeStatusPages() }

    private func makeStatusPages() -> [StatusPage] {
        // Page 0 — Home: Distance | State | Time
        let homeLeft = StatusBlock(
            id: "home.distance",
            primary: DistanceUtility.formatter(meters: tripDistanceLiveMiles),
            secondary: tripDistanceCommittedMiles > 0 ? DistanceUtility.formatter(meters: tripDistanceCommittedMiles) : nil,
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
            primary: TimeUtility.formatter(tripDurationLive),
            secondary: tripDurationCommitted > 0 ? TimeUtility.formatter(tripDurationCommitted) : nil,
            role: .value
        )
        var result: [StatusPage] = [
            StatusPage(id: "page.home", left: homeLeft, center: homeCenter, right: homeRight, tripType: nil)
        ]

        // Helper to build a totals page from a SortedTripTotalsModel
        func totalsPage(model: SortedTripTotalsModel) -> StatusPage {
            let left = StatusBlock(
                id: "\(model.tripType.name.capitalized).distance",
                primary: DistanceUtility.formatter(meters: model.totalDistance),
                secondary: nil,
                role: .value
            )
            let center = StatusBlock(
                id: "\(model.tripType.name.capitalized).count",
                primary: model.tripType.name.capitalized,
                secondary: "\(model.tripCount) trips",
                role: .status
            )
            let right = StatusBlock(
                id: "\(model.tripType.name.capitalized).duration",
                primary: TimeUtility.formatter(model.totalDuration),
                secondary: nil,
                role: .value
            )
            return StatusPage(id: "page.\(model.tripType.name.capitalized)", left: left, center: center, right: right, tripType: model.tripType)
        }

        // Pages 1-4 — Personal, Business, Custom, Unclassified
        result.append(totalsPage(model: personalTrips))
        result.append(totalsPage(model: businessTrips))
        result.append(totalsPage(model: customTrips))
        result.append(totalsPage(model: unclassifiedTrips))

        return result
    }
}
