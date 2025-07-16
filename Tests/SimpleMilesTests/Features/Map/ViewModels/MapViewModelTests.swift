//
//  MapViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class MapViewModelTests: XCTestCase {
    private var mockStore: MockTripSessionStore!
    private var viewModel: MapViewModel!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()

        mockStore.stubbedSessions = [
            TripSessionModel.mock(tripType: .business),
            TripSessionModel.mock(tripType: .personal),
            TripSessionModel.mock(tripType: .business)
        ]

        viewModel = MapViewModel(sessionStore: mockStore)
    }

    func testLoadSegmentsLoadsAllByDefault() {
        viewModel.loadSegments()
        XCTAssertEqual(viewModel.segments.count, 3)
    }

    func testLoadSegmentsFiltersByTripType() {
        viewModel.loadSegments(filter: .business)
        XCTAssertEqual(viewModel.segments.count, 2)

        viewModel.loadSegments(filter: .personal)
        XCTAssertEqual(viewModel.segments.count, 1)
    }

    func testLoadSegmentsWithNoMatchReturnsEmpty() {
        viewModel.loadSegments(filter: .unclassified)
        XCTAssertTrue(viewModel.segments.isEmpty)
    }
}
