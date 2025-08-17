import Foundation
import Combine

@MainActor
class MainStateDriver: ObservableObject {
    static let shared = MainStateDriver()
    @Published var mainState: MainModes = .main
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func initialize() {
        print("Main State Driver: Initialized")
    }
}
