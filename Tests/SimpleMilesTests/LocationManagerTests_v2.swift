import XCTest
@testable import SimpleMilesBackEnd
import CoreLocation

final class LocationManagerXCTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Reset notification throttle to avoid side effects between tests
        LocationManager.shared.resetNotificationThrottle()
    }

    func testNotificationThrottle() async throws {
        let manager = LocationManager.shared
        manager.resetNotificationThrottle()
        XCTAssertNil(manager.timeSinceLastNotification())
        XCTAssertTrue(manager.shouldNotifyUser(minInterval: 60))
        manager.markUserNotifiedNow()
        let interval = manager.timeSinceLastNotification()
        XCTAssertNotNil(interval)
        XCTAssertLessThan(interval!, 1)
        XCTAssertFalse(manager.shouldNotifyUser(minInterval: 60))
        manager.resetNotificationThrottle()
        XCTAssertNil(manager.timeSinceLastNotification())
        XCTAssertTrue(manager.shouldNotifyUser(minInterval: 60))
    }

    func testSingletonConsistency() async throws {
        let first = LocationManager.shared
        let second = LocationManager.shared
        XCTAssertTrue(first === second)
    }

    func testLocationPersistence() async throws {
        let point = LocationPoint(
            coordinate: CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
            timestamp: Date(),
            speed: 15,
            course: 220
        )
        // Persist location using selectors to access private methods
        let manager = LocationManager.shared
        let persistSelector = NSSelectorFromString("persistLastKnownLocation:")
        let loadSelector = NSSelectorFromString("loadLastKnownLocation")
        if manager.responds(to: persistSelector) && manager.responds(to: loadSelector) {
            _ = manager.perform(persistSelector, with: point)
            let loaded = manager.perform(loadSelector)?.takeUnretainedValue() as? LocationPoint
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded, point)
        }
    }

    func testShouldNotifyUserWithElapsedTime() async throws {
        let manager = LocationManager.shared
        manager.resetNotificationThrottle()
        XCTAssertTrue(manager.shouldNotifyUser(minInterval: 1))
        manager.markUserNotifiedNow()
        // Wait for 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)
        XCTAssertTrue(manager.shouldNotifyUser(minInterval: 1))
    }
}
