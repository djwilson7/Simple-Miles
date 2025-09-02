//
//  ManagerGuide.swift
//  SimpleMiles
//
//  File Guide for "Manager"
//
//  Purpose:
//  Managers coordinate cross-cutting concerns, aggregate data from multiple sources,
//  and expose a single, consistent stream of state and/or intents to the rest of the app.
//  They should be predictable, well-scoped, and explicit about threading and ownership.
//
//  Scope:
//  - A Manager is not a view model (UI-specific) and not a domain model (data-only).
//  - It binds multiple sources (stores, services, sensors) and publishes derived state.
//  - Examples: CameraManager (location + heading + orientation -> desired camera),
//

// MARK: - What belongs in a Manager file
/*
 - One primary manager type (final class or actor), clearly named (e.g., CameraManager)
 - Dependencies are grouped together (either injected or via singletons — both are acceptable)
 - Threading model explicit (e.g., @MainActor for UI-facing managers)
 - Published state (for UI/view models) and/or async APIs (for services)
 - Binding/subscriptions to sources (Combine/async sequences) centralized in one place
 - Minimal, focused domain methods to perform manager responsibilities
 - No heavy business logic that belongs in domain models/utilities
 - No direct UI code; managers expose state, not views
*/

// MARK: - Section Order (for all Manager files)
/*
 1) Imports (Foundation first; add frameworks as needed)
 2) File-level doc (what the manager coordinates)
 3) Type declaration (final class or actor; mark @MainActor if UI-facing)
 4) Dependencies (group together; may be injected or singletons)
 5) Published/Public State (exposed outputs)
 6) Private State (cancellables, caches, configuration)
 7) Init (set defaults, wire bindings)
 8) Public API (user intents, commands)
 9) Bindings (Combine/async streams wiring; private helpers)
10) Private Helpers (pure transforms, small utilities)
11) Lifecycle (deinit, cancellation)
12) Testing hooks/fixtures (behind DEBUG if needed)
*/

// MARK: - Naming & Scope
/*
 - Name managers after their responsibility (CameraManager, TravelStateManager)
 - Keep the API minimal and intention-revealing
 - Use internal/private for helpers; expose only what consumers need
 - If a manager is UI-facing, isolate it to the main actor (@MainActor)
*/

// MARK: - Concurrency & Threading
/*
 - UI-facing managers should be @MainActor and publish @Published state
 - Background work should be offloaded to Task { } or dedicated executors
 - Combine:
    - receive(on:) before mutating @Published state
    - store cancellables in a Set<AnyCancellable>
 - Swift Concurrency:
    - prefer async/await for service calls or timers
    - avoid mixing Combine and async unless necessary; keep boundaries clear
*/

// MARK: - Mutability & Identity
/*
 - Prefer immutable inputs (value types) and controlled mutation of manager state
 - If identity matters (e.g., a single coordinator), document singleton usage
 - If shared across modules, consider protocol abstraction for testability
*/

// MARK: - Error Handling
/*
 - Surface recoverable errors via dedicated published properties or async throws
 - Log non-fatal issues; avoid silent failures
 - Fail fast for programmer errors (preconditions), but not for runtime conditions
*/

// MARK: - Events & Outputs
/*
 - Clearly separate inputs (intents) and outputs (published state)
 - When publishing composite state (e.g., MapCamera), document units and thresholds
 - Debounce/throttle where appropriate; avoid over-publishing
*/

// MARK: - Copy/Paste Template (UI-facing Manager with Combine)
/*
import Foundation
import Combine
import SwiftUI

/// Coordinates X and Y to produce Z for UI consumption.
@MainActor
final class ExampleManager: ObservableObject {

    // MARK: - Dependencies (injection or singletons; group together)
    private let xSource: XSource
    private let ySource: YSource

    // MARK: - Published State (Outputs)
    @Published private(set) var zState: ZState = .initial

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    // Both DI and singleton usage are acceptable; pick one per use case.
    init(xSource: XSource = .shared, ySource: YSource = .shared) {
        self.xSource = xSource
        self.ySource = ySource
        bind()
    }

    // MARK: - Public API (Intents)
    func performUserIntent(_ intent: Intent) {
        // mutate state and/or forward to sources
    }

    // MARK: - Bindings (Streams wiring)
    private func bind() {
        Publishers.CombineLatest(xSource.$x, ySource.$y)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] x, y in
                guard let self else { return }
                self.zState = Self.reduce(x: x, y: y)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    private static func reduce(x: X, y: Y) -> ZState {
        // pure transformation
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
*/

// MARK: - Copy/Paste Template (Service Manager with async/await)
/*
import Foundation

/// Coordinates network/storage tasks and exposes async APIs.
/// Not necessarily @MainActor if it does not touch UI state.
final class ServiceManager {

    // MARK: - Dependencies (injection or singletons; group together)
    private let api: APIClient
    private let store: DataStore

    // MARK: - Init
    init(api: APIClient, store: DataStore) {
        self.api = api
        self.store = store
    }

    // MARK: - Public API
    func refresh() async throws {
        let remote = try await api.fetch()
        try await store.save(remote)
    }

    func load() async throws -> [Item] {
        try await store.load()
    }
}
*/

// MARK: - Testing & Fixtures
/*
 - Expose protocol for the manager when practical (ExampleManaging) to allow mocking
 - Provide deterministic inputs (test sources) and verify outputs
 - Use Swift Testing (or XCTest) to assert published state sequences
*/
/*
import Testing
@testable import SimpleMiles

@Suite("ExampleManager")
struct ExampleManagerTests {
    @Test
    func reducesXYtoZ() async throws {
        // Arrange test sources
        // Act + Assert on published state
        #expect(true)
    }
}
*/

// MARK: - Common MARK Tags (for Managers)
/*
 // MARK: - Dependencies
 // MARK: - Published State
 // MARK: - Private
 // MARK: - Init
 // MARK: - Public API
 // MARK: - Bindings
 // MARK: - Private Helpers
 // MARK: - Deinit
*/
