import XCTest
import Combine
@testable import SimpleMilesBackEnd

@MainActor
final class TravelStateManagerTests: XCTestCase {

    var manager: TravelStateManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        // Use a fresh instance for each test to ensure isolation
        manager = TravelStateManager(drivingStateManager: .shared, settings: .shared)
        cancellables = []
    }

    override func tearDown() {
        manager.reset()
        cancellables = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(manager.state, .idle)
        XCTAssertNil(manager.pauseRemainingTime)
        XCTAssertNil(manager.pauseTotalDuration)
    }

    func testDrivingTransitions() {
        // Mock driving started
        manager.handleDrivingStarted()
        XCTAssertEqual(manager.state, .traveling)
        XCTAssertNil(manager.pauseRemainingTime)
        
        // Mock driving stopped
        manager.handleDrivingStopped()
        XCTAssertEqual(manager.state, .paused)
        XCTAssertNotNil(manager.pauseRemainingTime)
        XCTAssertNotNil(manager.pauseTotalDuration)
    }

    func testPauseCountdown() async {
        manager.handleDrivingStarted()
        manager.handleDrivingStopped()
        
        XCTAssertEqual(manager.state, .paused)
        let initialRemaining = manager.pauseRemainingTime ?? 0
        XCTAssertTrue(initialRemaining > 0)

        let expectation = XCTestExpectation(description: "Pause timer ticks")
        
        manager.$pauseRemainingTime
            .compactMap { $0 }
            .filter { $0 < initialRemaining }
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(manager.state, .paused)
    }

    func testExtendPauseTimerWhileTraveling() {
        manager.handleDrivingStarted()
        XCTAssertEqual(manager.state, .traveling)
        XCTAssertNil(manager.pauseRemainingTime)
        
        // Extend while traveling (even if nil)
        manager.extendPauseTimer()
        let pauseSetting = SettingsManager.shared.pauseTimer
        XCTAssertEqual(manager.pauseRemainingTime, pauseSetting)
        
        // Extend again
        manager.extendPauseTimer()
        XCTAssertEqual(manager.pauseRemainingTime, pauseSetting * 2)
        
        let extendedTime = manager.pauseRemainingTime
        
        // Stop driving
        manager.handleDrivingStopped()
        XCTAssertEqual(manager.state, .paused)
        
        // Should NOT be reset to settings.pauseTimer because it was already set
        XCTAssertEqual(manager.pauseRemainingTime, extendedTime)
    }

    func testPauseTimerAccuracy() async {
        manager.handleDrivingStarted()
        manager.handleDrivingStopped()
        
        // Force a known value
        manager.pauseRemainingTime = 10.0
        
        let expectation = XCTestExpectation(description: "Pause timer ticks accurately")
        
        var ticks = 0
        manager.$pauseRemainingTime
            .compactMap { $0 }
            .dropFirst() // Ignore the 10.0 we just set
            .sink { remaining in
                ticks += 1
                if ticks == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
            
        await fulfillment(of: [expectation], timeout: 3.5)
        
        // After 2 ticks (approx 2s), remaining should be approx 8.0
        if let remaining = manager.pauseRemainingTime {
            XCTAssertTrue(remaining <= 8.5 && remaining >= 7.5, "Remaining should be approx 8.0, but was \(remaining)")
        } else {
            XCTFail("Remaining time should not be nil")
        }
    }

    func testPauseTimerExpiration() async {
        manager.handleDrivingStarted()
        manager.handleDrivingStopped()
        
        // Force a short timeout for testing
        manager.pauseRemainingTime = 1.1
        
        let expectation = XCTestExpectation(description: "Pause timer expires")
        
        manager.$state
            .dropFirst()
            .filter { $0 == .idle }
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(manager.state, .idle)
        XCTAssertNil(manager.pauseRemainingTime)
    }

    func testReset() {
        manager.handleDrivingStarted()
        manager.handleDrivingStopped()
        manager.reset()
        
        XCTAssertEqual(manager.state, .idle)
        XCTAssertNil(manager.pauseRemainingTime)
        XCTAssertNil(manager.pauseTimer)
    }
}
