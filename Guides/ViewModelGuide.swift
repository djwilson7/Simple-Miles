//
//  ViewModelGuide.swift
//  SimpleMiles
//
//  File Guide for "ViewModel"
//
//  Purpose:
//  A focused, copy‑pasteable guide for structuring ViewModel files.
//  Keep this concise and opinionated so every ViewModel looks and feels the same.
//  Prefer Swift Concurrency and a small, testable surface area.
//

// MARK: - What belongs in a ViewModel file
/*
 - One primary type: @MainActor final class MyFeatureViewModel: ObservableObject
 - UI-facing state only (@Published), minimal exposure (prefer private(set))
 - Orchestration of async work, streams, and business logic for a specific View/feature
 - Dependency injection for services/managers; avoid hard singletons unless justified
 - No rendering code; Views subscribe and render
 - Keep domain types (models, services) outside; reference via protocols
*/

// MARK: - Section Order (for all ViewModel files)
/*
 1) Imports (Apple first, then project)
 2) File-level doc (1–2 lines: what this ViewModel does)
 3) Type declaration (@MainActor final class SomeViewModel: ObservableObject)
 4) Singleton (only if justified) or Factory (static make) if needed
 5) Dependencies (injected via init; prefer let)
 6) Published State (UI-observable) — group by concern
 7) Private State (caches, tasks, cancellables, timers)
 8) Init (assign deps, call bind())
 9) Bindings (private bind() to wire Combine/async streams)
10) Public API (user intents: load, refresh, select, navigate)
11) Private Helpers (transformations, formatting, mapping)
12) Teardown / Deinit (cancel tasks/subscriptions/observers)
*/

// MARK: - Naming & Scope
/*
 - Name the file and type the same (MapViewModel.swift → MapViewModel)
 - Mark the type @MainActor; mutate @Published only on main actor
 - Keep dependencies private; expose minimal surface with private(set)
 - Group related @Published properties; document with short comments
 - Use // MARK: consistently; no floating code outside a section
 - Keep the API oriented around user intents (verbs), not implementation details
*/

// MARK: - Concurrency & Streams
/*
 - Prefer async/await for request/compute flows; hold Task? for cancellation
 - Use Task { @MainActor in ... } or mark the class @MainActor to ensure main-thread UI state
 - For Combine sources, .receive(on: RunLoop.main/DispatchQueue.main) before touching @Published
 - For AsyncSequence sources, iterate with for await; cancel via Task cancellation
 - Avoid heavy work in init; trigger via onAppear()/load() unless essential
 - Bounce rapid user inputs with debounce/throttle where appropriate
*/

// MARK: - Error Handling
/*
 - Map domain errors to a small, UI-friendly state (e.g., errorMessage or typed enum)
 - Do not throw out of user-intent methods called by Views; update published error state instead
 - Prefer user-presentable copy over raw error descriptions
 - Consider a lightweight ErrorState enum for richer UI (empty, loading, loaded, failed)
*/

// MARK: - Cancellation & Lifecycles
/*
 - Keep references to in-flight Task<?> and cancel before starting new work
 - Cancel work on state changes and in deinit
 - If the View disappears and work should stop, expose a cancel() or handle in onDisappear
*/

// MARK: - Singleton Guidance
/*
 - Use static let shared only for true app-wide models (e.g., SnapshotViewModel)
 - Prefer injected instances or factories in most features
 - If using shared, keep API small and document why
*/

// MARK: - Testing Guidance
/*
 - Inject dependencies via protocols to enable mocking
 - Keep initializers light; trigger flows from explicit methods (load/refresh)
 - Structure async work so tests can await completion deterministically
 - Use Swift Testing (import Testing) for concise async tests
 - Cancel tasks and subscriptions in deinit and in test tearDown
*/

// MARK: - Copy/Paste Template (Minimal ViewModel — Async/Await)
/*
import Foundation
import Combine
import SwiftUI

/// Short summary: what this ViewModel orchestrates and which View(s) consume it.
@MainActor
final class FeatureViewModel: ObservableObject {

    // MARK: - Singleton (avoid unless justified)
    // static let shared = FeatureViewModel(service: LiveService(), settings: SettingsManager.shared)

    // MARK: - Dependencies
    private let service: FeatureServicing
    private let settings: SettingsManaging
    // Add other managers as needed (e.g., modelContext for SwiftData/Core Data, logger, etc.)

    // MARK: - Published State (UI)
    /// Drives loading spinners and disables inputs during work.
    @Published var isLoading: Bool = false

    /// Data the View renders (keep value types where possible).
    @Published private(set) var items: [FeatureItem] = []

    /// Presentable error surface (nil when no error).
    @Published var errorMessage: String? = nil

    /// Navigation/selection state bound to the View.
    @Published var selectionID: FeatureItem.ID? = nil

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>? = nil
    private var streamTask: Task<Void, Never>? = nil

    // MARK: - Init
    init(service: FeatureServicing, settings: SettingsManaging) {
        self.service = service
        self.settings = settings
        bind()
    }

    // MARK: - Bindings
    private func bind() {
        // Example: react to settings changes and derive UI state
        settings.themePublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyTheme() }
            .store(in: &cancellables)

        // Example: start listening to a live async sequence (if applicable)
        // startStream()
    }

    // MARK: - Public API (User Intents)
    /// Call from View.onAppear or .task to kick off loading.
    func onAppear() {
        if items.isEmpty { load() }
        // startStream()
    }

    /// Explicit load with cancellation of in-flight work.
    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchItems()
        }
    }

    /// Optional: manual refresh or pull-to-refresh.
    func refresh() { load() }

    /// Update selection (drives navigation or detail panes).
    func select(id: FeatureItem.ID?) { selectionID = id }

    /// Optional: stop background work when view disappears.
    func onDisappear() {
        // stopStream()
    }

    // MARK: - Private Helpers
    private func applyTheme() {
        // Update derived UI state if needed.
    }

    private func fetchItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await service.fetchItems()
            items = result
            errorMessage = nil
        } catch {
            errorMessage = Self.userMessage(for: error)
            items = []
        }
    }

    private func startStream() {
        guard streamTask == nil else { return }
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await update in service.liveUpdates() {
                    // Apply updates to published state
                    self.items = update.items
                }
            } catch is CancellationError {
                // Normal during teardown
            } catch {
                self.errorMessage = Self.userMessage(for: error)
            }
        }
    }

    private func stopStream() {
        streamTask?.cancel()
        streamTask = nil
    }

    private static func userMessage(for error: Error) -> String {
        // Map domain errors to user-friendly copy.
        "Something went wrong. Please try again."
    }

    // MARK: - Deinit
    deinit {
        loadTask?.cancel()
        stopStream()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - Protocols (for dependency injection)
// Define these in your feature module; included here for completeness.
/*
protocol FeatureServicing {
    func fetchItems() async throws -> [FeatureItem]
    func liveUpdates() -> AsyncThrowingStream<FeatureUpdate, Error>
}

protocol SettingsManaging {
    var themePublisher: AnyPublisher<AppTheme, Never> { get }
}

// Example models
struct FeatureItem: Identifiable, Equatable {
    var id: UUID
    var title: String
}

struct FeatureUpdate {
    var items: [FeatureItem]
}

enum AppTheme: Equatable {
    case system, light, dark
}
*/
*/

// MARK: - Copy/Paste Template (Minimal ViewModel — Combine)
/*
import Foundation
import Combine
import SwiftUI

/// Alternative template if your dependencies are Combine-first.
@MainActor
final class FeatureViewModel_Combine: ObservableObject {

    // MARK: - Dependencies
    private let service: FeatureServiceCombine
    private let settings: SettingsManaging

    // MARK: - Published State
    @Published private(set) var items: [FeatureItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(service: FeatureServiceCombine, settings: SettingsManaging) {
        self.service = service
        self.settings = settings
        bind()
    }

    // MARK: - Bindings
    private func bind() {
        settings.themePublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { _ in /* apply theme if needed */ }
            .store(in: &cancellables)
    }

    // MARK: - Public API
    func load() {
        isLoading = true
        errorMessage = nil

        service.fetchItemsPublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.items = []
                    self.errorMessage = Self.userMessage(for: error)
                }
            } receiveValue: { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers
    private static func userMessage(for error: Error) -> String {
        "Something went wrong. Please try again."
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// Dependency example
/*
protocol FeatureServiceCombine {
    func fetchItemsPublisher() -> AnyPublisher<[FeatureItem], Error>
}
*/
*/

// MARK: - Access Control & Testing
/*
 - Prefer private for dependencies and helpers; use private(set) for observed state
 - Inject dependencies via init with protocols to enable mocking
 - Keep initializers light; test load/refresh flows with async tests
 - Cancel tasks and subscriptions deterministically in tests (tearDown)
 - Use Swift Testing:

 import Testing

 @Suite("FeatureViewModel")
 struct FeatureViewModelTests {

     @Test("Loads items successfully")
     func loadsItems() async throws {
         let service = MockService(items: [.init(id: .init(), title: "A")])
         let settings = MockSettings()
         let vm = await FeatureViewModel(service: service, settings: settings)

         await vm.load()
         // Spin the runloop if needed or await mocked suspension points
         #expect(await vm.items.count == 1)
         #expect(await vm.errorMessage == nil)
     }
 }
*/

// MARK: - Common MARK Tags (for ViewModels)
/*
 // MARK: - Singleton
 // MARK: - Dependencies
 // MARK: - Published State
 // MARK: - Private State
 // MARK: - Init
 // MARK: - Bindings
 // MARK: - Public API
 // MARK: - Private Helpers
 // MARK: - Deinit
*/
