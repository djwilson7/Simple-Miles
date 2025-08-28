import Foundation
import Combine

@MainActor
class MainStateDriver: ObservableObject {
    static let shared = MainStateDriver()
    @Published var mainState: MainModes = .main
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        $mainState
            .sink { newState in
                Log("Main State Changed to: \(newState)")
                if newState == .main {
                    TripStatusViewModel.shared.clearSelected()
                }
            }
            .store(in: &cancellables)
    }
}
