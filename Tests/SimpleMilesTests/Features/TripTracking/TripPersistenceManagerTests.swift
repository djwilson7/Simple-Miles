//
//  TripPersistenceManagerTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class TripPersistenceManagerTests: XCTestCase {
    private var manager: TripPersistenceManager!
    private var store: MockTripSessionStore!

    override func setUp() {
        store = MockTripSessionStore()
        manager = TripPersistenceManager(store: store)
    }

    func test_save_delegatesToStore() {
        let session = MockTripSessionModel.make()
        manager.save(session)

        XCTAssertEqual(store.mockTrips.count, 1)
        XCTAssertEqual(store.mockTrips.first?.id, session.id)
    }

    func test_clearAllTrips_clearsStore() {
        store.mockTrips = [MockTripSessionModel.make()]
        manager.clearAllTrips()

        XCTAssertTrue(store.mockTrips.isEmpty)
    }

    func test_fetchAll_returnsStoredTrips() {
        let session = MockTripSessionModel.make()
        store.mockTrips = [session]

        let results = manager.fetchAll()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, session.id)
    }
}
