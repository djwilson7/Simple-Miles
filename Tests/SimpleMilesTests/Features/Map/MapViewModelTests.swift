//
//  MapViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

// MARK: - MapViewModelTests.swift

import XCTest
@testable import SimpleMiles

final class MapViewModelTests: XCTestCase {
    private var viewModel: MapViewModel!
    private var mockStore: MockTripSessionStore!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        super.tearDown()
    }

    func test_loadSegments_withoutFilter_loadsAllSegments() {
        let segment1 = MockTripSegmentModel.make()
        let segment2 = MockTripSegmentModel.make()
        let session = MockTripSessionModel.make(segments: [segment1, segment2])
        mockStore.save(session)

        viewModel = MapViewModel(sessionStore: mockStore)
        XCTAssertEqual(viewModel.segments.count, 2)
    }

    func test_loadSegments_withMatchingFilter_loadsMatchingSegments() {
        let matchType = TripType.business
        let segment = MockTripSegmentModel.make()
        let matchingSession = MockTripSessionModel.make(tripType: matchType, segments: [segment])
        let nonMatchingSession = MockTripSessionModel.make(tripType: .personal, segments: [MockTripSegmentModel.make()])

        mockStore.mockTrips = [matchingSession, nonMatchingSession]

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadSegments(filter: matchType)

        XCTAssertEqual(viewModel.segments, matchingSession.segments)
    }

    func test_loadSegments_withNonMatchingFilter_loadsEmpty() {
        let session = MockTripSessionModel.make(tripType: .personal, segments: [MockTripSegmentModel.make()])
        mockStore.save(session)

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadSegments(filter: .business)

        XCTAssertTrue(viewModel.segments.isEmpty)
    }
}
