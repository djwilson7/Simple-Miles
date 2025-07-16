//
//  TripHistoryViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TripHistoryViewModelTests: XCTestCase {

    private var mockStore: MockTripSessionStore!
    private var viewModel: TripHistoryViewModel!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
        viewModel = TripHistoryViewModel(store: mockStore)
    }

    func testLoadFetchesSessionsFromStore() {
        let expected = TripSessionModel(id: UUID(), startTime: Date(), endTime: Date(), distance: 50, segments: [])
        mockStore.stubbedSessions = [expected]

        viewModel.load()

        XCTAssertEqual(viewModel.sessions.count, 1)
        XCTAssertEqual(viewModel.sessions.first?.id, expected.id)
    }

    func testDeleteCallsStoreAndReloads() {
        let idToDelete = UUID()
        mockStore.stubbedSessions = [
            TripSessionModel(id: idToDelete, startTime: Date(), endTime: Date(), distance: 10, segments: []),
            TripSessionModel(id: UUID(), startTime: Date(), endTime: Date(), distance: 20, segments: [])
        ]

        viewModel.load()
        viewModel.delete(sessionID: idToDelete)

        XCTAssertEqual(mockStore.deletedIDs, [idToDelete])
        XCTAssertTrue(mockStore.didFetchAfterDelete)
    }
    
    func testLoadWithNoSessionsYieldsEmptyList() {
        mockStore.stubbedSessions = []
        viewModel.load()
        XCTAssertEqual(viewModel.sessions.count, 0)
    }

    func testDeleteNonexistentSessionDoesNotCrash() {
        mockStore.stubbedSessions = [
            TripSessionModel(id: UUID(), startTime: Date(), endTime: Date(), distance: 10, segments: [])
        ]
        viewModel.load()

        let nonexistentID = UUID()
        viewModel.delete(sessionID: nonexistentID)

        XCTAssertEqual(viewModel.sessions.count, 1)
        XCTAssertFalse(mockStore.deletedIDs.contains(nonexistentID))
    }

    func testMultipleLoadsDoNotCauseDuplication() {
        let session = TripSessionModel(id: UUID(), startTime: Date(), endTime: Date(), distance: 25, segments: [])
        mockStore.stubbedSessions = [session]

        viewModel.load()
        viewModel.load()
        XCTAssertEqual(viewModel.sessions.count, 1)
        XCTAssertEqual(viewModel.sessions.first?.id, session.id)
    }

}
