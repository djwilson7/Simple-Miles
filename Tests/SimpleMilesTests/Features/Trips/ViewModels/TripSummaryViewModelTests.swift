//
//  TripSummaryViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TripSummaryViewModelTests: XCTestCase {

    func testSummaryLoadsTotalDistanceAndTripCount() {
        let trip1 = TripSessionModel(distance: 1000, tripType: .business)
        let trip2 = TripSessionModel(distance: 2000, tripType: .personal)
        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = [trip1, trip2]

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.totalTrips, 2)
        XCTAssertEqual(sut.totalDistance, 3000)
    }

    func testTripCountByTypeReturnsCorrectClassificationBreakdown() {
        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = [
            TripSessionModel(tripType: .business),
            TripSessionModel(tripType: .business),
            TripSessionModel(tripType: .personal)
        ]

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.tripCount(for: .business), 2)
        XCTAssertEqual(sut.tripCount(for: .personal), 1)
        XCTAssertEqual(sut.tripCount(for: .unclassified), 0)
    }

    func testPercentageReturnsExpectedValues() {
        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = [
            TripSessionModel(tripType: .business),
            TripSessionModel(tripType: .personal),
            TripSessionModel(tripType: .personal)
        ]

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.percentage(for: .personal), 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(sut.percentage(for: .unclassified), 0.0)
    }

    func testFormattedTotalDistanceReturnsStringInMiles() {
        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = [TripSessionModel(distance: 1609.34)] // 1 mi

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.formattedTotalDistance(), "1.0 mi")
    }
    
    func testEmptyStoreResultsInZeroedSummary() {
        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = []

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.totalTrips, 0)
        XCTAssertEqual(sut.totalDistance, 0)
        XCTAssertEqual(sut.percentage(for: .business), 0)
        XCTAssertEqual(sut.tripCount(for: .unclassified), 0)
    }

    func testSummaryHandlesOnlyUnclassifiedTrips() {
        let trip1 = TripSessionModel(distance: 800, tripType: .unclassified)
        let trip2 = TripSessionModel(distance: 1200, tripType: .unclassified)

        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = [trip1, trip2]

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.totalTrips, 2)
        XCTAssertEqual(sut.tripCount(for: .unclassified), 2)
        XCTAssertEqual(sut.percentage(for: .unclassified), 1.0)
        XCTAssertEqual(sut.formattedTotalDistance(), "1.2 mi", "Should convert 2000m to ~1.2 mi")
    }

    func testPercentageIsZeroForTypesNotPresent() {
        let mockStore = MockTripSessionStore()
        mockStore.stubbedSessions = [
            TripSessionModel(tripType: .business),
            TripSessionModel(tripType: .business)
        ]

        let sut = TripSummaryViewModel(store: mockStore)

        XCTAssertEqual(sut.percentage(for: .personal), 0.0)
        XCTAssertEqual(sut.percentage(for: .unclassified), 0.0)
    }

}
