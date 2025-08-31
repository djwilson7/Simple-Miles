import Foundation
import Combine

@MainActor
class TripSubMenuViewModel: ObservableObject {
    static let shared = TripSubMenuViewModel()

    @Published var currentTripType: TripType? = nil
    @Published var isVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var tripStatusViewModel = TripStatusViewModel.shared

    init() {
        tripStatusViewModel.$selectedTripType
            .sink { [weak self] type in
                Log("Current Trip Type: \(String(describing: type))")
                self?.currentTripType = type
                self?.isVisible = (type != nil)
            }
            .store(in: &cancellables)
    }
    
    func hide() {
        isVisible = false
    }
}
