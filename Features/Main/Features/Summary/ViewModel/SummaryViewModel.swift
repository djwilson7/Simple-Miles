// MARK: - ViewModel
import Foundation
import Combine

final class SummaryViewModel: ObservableObject {
    static let shared = SummaryViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    @Published var pages: [SummaryPage] = [.miles, .trips, .time, .avg]
    @Published var currentIndex: Int = 0
    
    @Published var tripType: TripType?
    @Published var milesData: MilesData?
    
    init() {
        TripStatusViewModel.shared.$selectedTripType
            .sink { [weak self] selectedTripType in
                if let type = selectedTripType {
                    self?.tripType = type
                    self?.milesData = try? MilesData(tripType: type)
                } else {
                    self?.tripType = nil
                    self?.milesData = nil
                }
            }
            .store(in: &cancellables)
        
    }

}
