//  TripSummaryViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: aggregation of session data from path-based model, total trip count/distance calculation, per-type trip counts and percentages,
//  and formatted display of total mileage. Suite ensures summary logic is correct for populated, empty, and boundary scenarios.

import XCTest
@testable import SimpleMiles

final class TripSummaryViewModelTests: XCTestCase {
    private var viewModel: TripSummaryViewModel!
    private var mockStore: MockTripSessionStore!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
        viewModel = TripSummaryViewModel(store: mockStore)
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality

    func test_loadSummary_calculatesAggregateMetrics() {
        let trip1 = MockTripSessionModel.make(distance: 1000, tripType: .personal)
        let trip2 = MockTripSessionModel.make(distance: 2000, tripType: .business)
        let trip3 = MockTripSessionModel.make(distance: 1500, tripType: .personal)

        mockStore.mockTrips = [trip1, trip2, trip3]
        viewModel.loadSummary()

        XCTAssertEqual(viewModel.totalTrips, 3)
        XCTAssertEqual(viewModel.totalDistance, 4500)
        XCTAssertEqual(viewModel.tripCount(for: .personal), 2)
        XCTAssertEqual(viewModel.tripCount(for: .business), 1)
    }

    func test_percentage_returnsCorrectRatio() {
        mockStore.mockTrips = [
            MockTripSessionModel.make(tripType: .personal),
            MockTripSessionModel.make(tripType: .business),
            MockTripSessionModel.make(tripType: .personal)
        ]
        viewModel.loadSummary()

        XCTAssertEqual(viewModel.percentage(for: .personal), 2.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(viewModel.percentage(for: .business), 1.0 / 3.0, accuracy: 0.01)
    }

    func test_formattedTotalDistance_returnsReadableString() {
        mockStore.mockTrips = [
            MockTripSessionModel.make(distance: 1609.34 * 3.2)
        ]
        viewModel.loadSummary()

        XCTAssertEqual(viewModel.formattedTotalDistance(), "3.2 mi")
    }

    // MARK: - Edge Cases

    func test_tripCount_defaultsToZeroWhenMissing() {
        mockStore.mockTrips = []
        viewModel.loadSummary()

        XCTAssertEqual(viewModel.tripCount(for: .business), 0)
        XCTAssertEqual(viewModel.totalTrips, 0)
        XCTAssertEqual(viewModel.totalDistance, 0)
    }

    func test_percentage_whenNoTrips_returnsZero() {
        mockStore.mockTrips = []
        viewModel.loadSummary()

        XCTAssertEqual(viewModel.percentage(for: .personal), 0)
        XCTAssertEqual(viewModel.percentage(for: .business), 0)
    }

    func test_formattedTotalDistance_zeroDistance_returnsZeroMiles() {
        mockStore.mockTrips = []
        viewModel.loadSummary()

        XCTAssertEqual(viewModel.formattedTotalDistance(), "0.0 mi")
    }
}
