import Foundation
import Combine

/// Orchestrates paging and data fetching for SummaryView.
/// Listens to the selected trip type and exposes summary datasets for charts/cards.
@MainActor
final class SummaryViewModel: ObservableObject {

    // MARK: - Singleton
    static let shared = SummaryViewModel()

    // MARK: - Published State (UI)
    /// The currently selected page index (bound by SummaryView's TabView and indicators).
    @Published var currentIndex: Int = 0

    /// Selected trip type driving the summary datasets.
    @Published private(set) var tripType: TripType?

    /// Summary datasets consumed by the view's pages.
    @Published private(set) var breakdownData: BreakdownData?
    @Published private(set) var dowData: DOWData?
    @Published private(set) var hourData: HourHistogramData?
    @Published private(set) var weeklyInsights: WeekInsightsData?

    /// True when datasets are being computed.
    @Published private(set) var isLoading: Bool = false

    // MARK: - Configuration (Static)
    /// The ordered list of summary pages rendered by SummaryView.
    let pages: [SummaryPage] = [.theSplit, .weeklyRitual, .dailyRhythm, .weekInsights]

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        bind()
    }

    // MARK: - Bindings
    private func bind() {
        SnapshotViewModel.shared.$selectedTripType
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedTripType in
                guard let self else { return }
                self.tripType = selectedTripType
                
                // Reset data and set loading state
                self.breakdownData = nil
                self.dowData = nil
                self.hourData = nil
                self.weeklyInsights = nil
                
                if let type = selectedTripType {
                    self.isLoading = true
                    Task {
                        // Compute datasets on demand for the selected type.
                        let b = try? BreakdownData(tripType: type)
                        let d = try? DOWData(tripType: type)
                        let h = try? HourHistogramData(tripType: type)
                        let w = try? WeekInsightsData(tripType: type)
                        
                        // Update on MainActor (Task is already on MainActor)
                        self.breakdownData = b
                        self.dowData = d
                        self.hourData = h
                        self.weeklyInsights = w
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
