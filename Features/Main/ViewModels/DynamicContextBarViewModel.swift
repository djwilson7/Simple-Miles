import Combine
import SwiftUI

@MainActor
class DynamicContextBarViewModel: ObservableObject {
    static let shared = DynamicContextBarViewModel()
    @Published var mainState: MainModes = .main
    private var cancellables = Set<AnyCancellable>()

    // Private initializer to enforce singleton usage
    private init() {
        MainStateDriver.shared.$mainState
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$mainState)
    }
}
