//
//  TripHistoryViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class TripHistoryViewModelTests: XCTestCase {
    private var viewModel: TripHistoryViewModel!
    private var mockStore: MockTripSessionStore!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
        viewModel = TripHistoryViewModel(store: mockStore)
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        super.tearDown()
    }

    func test_load_populatesSessionsFromStore() {
        let trip1 = MockTripSessionModel.make()
        let trip2 = MockTripSessionModel.make()
        mockStore.mockTrips = [trip1, trip2]

        viewModel.load()

        XCTAssertEqual(viewModel.sessions.count, 2)
        XCTAssertEqual(viewModel.sessions.map(\.id), [trip1.id, trip2.id])
    }

    func test_delete_removesTripFromStoreAndReloads() {
        let trip = MockTripSessionModel.make()
        mockStore.save(trip)

        viewModel.load()
        viewModel.delete(sessionID: trip.id)

        XCTAssertTrue(viewModel.sessions.isEmpty)
        XCTAssertTrue(mockStore.mockTrips.isEmpty)
    }
}
