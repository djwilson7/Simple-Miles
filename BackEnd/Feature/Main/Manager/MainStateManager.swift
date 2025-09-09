import Foundation
import Combine

/// Coordinates the high-level application navigation state.
/// Publishes the current MainState and reacts to transitions that affect global app behavior.
@MainActor
final class MainStateManager: ObservableObject {

    // MARK: - Types
    enum MainState: String, CaseIterable, Identifiable {
        case main = "main"
        case settings = "settings"
        case review = "review"
        case summary = "summary"
        var id: String { rawValue }
    }

    // MARK: - Singleton
    static let shared = MainStateManager()

    // MARK: - Published State (Outputs)
    @Published var state: MainState = .main

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        bindStateTransitions()
    }

    // MARK: - Bindings (Streams wiring)
    private func bindStateTransitions() {
        $state
            .receive(on: DispatchQueue.main)
            .sink { newState in
                Log("Main State Changed to: \(newState)")
            }
            .store(in: &cancellables)
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
