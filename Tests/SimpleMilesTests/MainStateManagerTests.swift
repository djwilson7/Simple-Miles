import XCTest
import Combine
@testable import SimpleMilesBackEnd

@MainActor
final class MainStateManagerXCTests: XCTestCase {

    func testSingletonInstance() {
        let instance1 = MainStateManager.shared
        let instance2 = MainStateManager.shared
        XCTAssertTrue(instance1 === instance2, "MainStateManager should be a singleton.")
    }

    func testInitialState() {
        let manager = MainStateManager()
        XCTAssertEqual(manager.state, .main)
    }

    func testStateTransition() {
        let manager = MainStateManager()
        
        let expectation = XCTestExpectation(description: "State changes")
        var receivedStates: [MainStateManager.MainState] = []
        
        let cancellable = manager.$state
            .dropFirst() // Ignore current state
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count == 2 {
                    expectation.fulfill()
                }
            }
        
        manager.state = .settings
        manager.state = .review
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedStates, [.settings, .review])
        XCTAssertEqual(manager.state, .review)
        
        cancellable.cancel()
    }

    func testMainStateEnum() {
        let allCases = MainStateManager.MainState.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.main))
        XCTAssertTrue(allCases.contains(.settings))
        XCTAssertTrue(allCases.contains(.review))
        XCTAssertTrue(allCases.contains(.summary))
        
        XCTAssertEqual(MainStateManager.MainState.main.id, "main")
        XCTAssertEqual(MainStateManager.MainState.settings.id, "settings")
        XCTAssertEqual(MainStateManager.MainState.review.id, "review")
        XCTAssertEqual(MainStateManager.MainState.summary.id, "summary")
        
        XCTAssertEqual(MainStateManager.MainState.main.rawValue, "main")
        XCTAssertEqual(MainStateManager.MainState.settings.rawValue, "settings")
        XCTAssertEqual(MainStateManager.MainState.review.rawValue, "review")
        XCTAssertEqual(MainStateManager.MainState.summary.rawValue, "summary")
    }

    func testMainStateInitialization() {
        XCTAssertEqual(MainStateManager.MainState(rawValue: "main"), .main)
        XCTAssertEqual(MainStateManager.MainState(rawValue: "settings"), .settings)
        XCTAssertEqual(MainStateManager.MainState(rawValue: "review"), .review)
        XCTAssertEqual(MainStateManager.MainState(rawValue: "summary"), .summary)
        XCTAssertNil(MainStateManager.MainState(rawValue: "invalid"))
    }

    func testMainStateEqualityAndHashing() {
        XCTAssertEqual(MainStateManager.MainState.main, .main)
        XCTAssertNotEqual(MainStateManager.MainState.main, .settings)
        
        let set: Set<MainStateManager.MainState> = [.main, .settings, .main]
        XCTAssertEqual(set.count, 2)
    }

    func testDeinit() {
        // This test creates a local instance and releases it to cover deinit.
        autoreleasepool {
            _ = MainStateManager()
        }
    }
}
