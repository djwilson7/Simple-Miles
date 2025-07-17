//
//  TripDetailViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class TripDetailViewModelTests: XCTestCase {
    private var trip: TripSessionModel!
    private var viewModel: TripDetailViewModel!

    override func setUp() {
        super.setUp()
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(125) // 2m 5s

        let segment1 = MockTripSegmentModel.make(
            startTime: start,
            endTime: start.addingTimeInterval(60),
            distance: 500,
            startCoordinate: CoordinateModel(latitude: 10, longitude: 10),
            endCoordinate: CoordinateModel(latitude: 11, longitude: 11)
        )

        let segment2 = MockTripSegmentModel.make(
            startTime: start.addingTimeInterval(60),
            endTime: end,
            distance: 400,
            startCoordinate: CoordinateModel(latitude: 11, longitude: 11),
            endCoordinate: CoordinateModel(latitude: 12, longitude: 12)
        )

        trip = MockTripSessionModel.make(
            startTime: start,
            endTime: end,
            distance: 900,
            segments: [segment1, segment2]
        )

        viewModel = TripDetailViewModel(trip: trip)
    }

    override func tearDown() {
        viewModel = nil
        trip = nil
        super.tearDown()
    }

    func test_distanceText_returnsFormattedMiles() {
        XCTAssertEqual(viewModel.distanceText, "0.6 mi")
    }

    func test_durationText_returnsFormattedTime() {
        XCTAssertEqual(viewModel.durationText, "2m 5s")
    }

    func test_startDateText_isValidString() {
        let dateString = viewModel.startDateText
        XCTAssertFalse(dateString.isEmpty)
    }

    func test_endDateText_isValidString_whenEnded() {
        let dateString = viewModel.endDateText
        XCTAssertFalse(dateString.isEmpty)
        XCTAssertNotEqual(dateString, "In Progress")
    }

    func test_endDateText_whenNil_returnsInProgress() {
        trip.endTime = nil
        viewModel = TripDetailViewModel(trip: trip)
        XCTAssertEqual(viewModel.endDateText, "In Progress")
    }

    func test_segmentCount_returnsCount() {
        XCTAssertEqual(viewModel.segmentCount, 2)
    }

    func test_startCoordinate_returnsFirstSegmentStart() {
        XCTAssertEqual(viewModel.startCoordinate.latitude, 10)
        XCTAssertEqual(viewModel.startCoordinate.longitude, 10)
    }

    func test_endCoordinate_returnsLastSegmentEnd() {
        XCTAssertEqual(viewModel.endCoordinate.latitude, 12)
        XCTAssertEqual(viewModel.endCoordinate.longitude, 12)
    }
}
