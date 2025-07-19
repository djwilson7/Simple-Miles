//  TripHistoryViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: initial session loading from the store, session deletion and reload, and correct propagation of path-based session data.
//  Suite ensures published sessions array reflects the store after all mutations and boundary flows.

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

    // MARK: - Basic Functionality

    func test_load_populatesSessionsFromStore() {
        let path1 = [CoordinateModel(latitude: 1, longitude: 1), CoordinateModel(latitude: 2, longitude: 2)]
        let path2 = [CoordinateModel(latitude: 3, longitude: 3)]
        let trip1 = MockTripSessionModel.make(path: path1)
        let trip2 = MockTripSessionModel.make(path: path2)
        mockStore.mockTrips = [trip1, trip2]

        viewModel.load()

        XCTAssertEqual(viewModel.sessions.count, 2)
        XCTAssertEqual(viewModel.sessions.map(\.id), [trip1.id, trip2.id])
        XCTAssertEqual(viewModel.sessions[0].path, path1)
        XCTAssertEqual(viewModel.sessions[1].path, path2)
    }

    func test_delete_removesTripFromStoreAndReloads() {
        let path = [CoordinateModel(latitude: 5, longitude: 5)]
        let trip = MockTripSessionModel.make(path: path)
        mockStore.save(trip)

        viewModel.load()
        viewModel.delete(sessionID: trip.id)

        XCTAssertTrue(viewModel.sessions.isEmpty)
        XCTAssertTrue(mockStore.mockTrips.isEmpty)
    }

    // MARK: - Edge Cases

    func test_load_withNoSessions_resultsInEmpty() {
        mockStore.mockTrips = []
        viewModel.load()
        XCTAssertTrue(viewModel.sessions.isEmpty)
    }

    func test_delete_onNonexistentSession_doesNotCrash() {
        // Should not crash or throw when session ID doesn't exist
        viewModel.delete(sessionID: UUID())
        // Sessions array remains empty and nothing removed
        XCTAssertTrue(viewModel.sessions.isEmpty)
        XCTAssertTrue(mockStore.mockTrips.isEmpty)
    }
}
