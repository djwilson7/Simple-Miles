// MARK: - ViewModel
import Foundation
import Combine

final class SummaryViewModel: ObservableObject {
    static let shared = SummaryViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    @Published var pages: [SummaryPage] = [.theSplit, .weeklyRitual, .dailyRhythm, .avg]
    @Published var currentIndex: Int = 0
    
    @Published var tripType: TripType?
    @Published var breakdownData: BreakdownData?
    @Published var dowData: DOWData?
    @Published var hourData: HourHistogramData?
    
    init() {
        TripStatusViewModel.shared.$selectedTripType
            .sink { [weak self] selectedTripType in
                if let type = selectedTripType {
                    self?.tripType = type
                    self?.breakdownData = try? BreakdownData(tripType: type)
                    self?.dowData = try? DOWData(tripType: type)
                    self?.hourData = try? HourHistogramData(tripType: type)
                } else {
                    self?.tripType = nil
                    self?.breakdownData = nil
                    self?.dowData = nil
                    self?.hourData = nil
                }
            }
            .store(in: &cancellables)
    }

}
