import Foundation
import Combine

enum MainState: String, CaseIterable, Identifiable {
    case main = "main"
    case settings = "settings"
    case review = "review"
    case summary = "summary"
    var id: String { rawValue }
}

@MainActor
class MainStateManager: ObservableObject {
    static let shared = MainStateManager()
    @Published var state: MainState = .main
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        $state
            .sink { newState in
                Log("Main State Changed to: \(newState)")
                if newState == .main {
                    SnapshotViewModel.shared.clearSelected()
                }
            }
            .store(in: &cancellables)
    }
}
