//  TripDetailViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: distance/duration formatting, start/end time strings, in-progress logic, path point counting, path start/end extraction,
//  and all computed property behaviors exposed by TripDetailViewModel using the path-based model.
//  Suite guarantees correct output for typical, boundary, and incomplete trip session scenarios, including empty path cases.

import XCTest
@testable import SimpleMiles

final class TripDetailViewModelTests: XCTestCase {
    private var trip: TripSessionModel!
    private var viewModel: TripDetailViewModel!

    override func setUp() {
        super.setUp()
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(125) // 2m 5s

        let path: [CoordinateModel] = [
            CoordinateModel(latitude: 10, longitude: 10),
            CoordinateModel(latitude: 11, longitude: 11),
            CoordinateModel(latitude: 12, longitude: 12)
        ]

        trip = MockTripSessionModel.make(
            startTime: start,
            endTime: end,
            distance: 900,
            path: path
        )

        viewModel = TripDetailViewModel(trip: trip)
    }

    override func tearDown() {
        viewModel = nil
        trip = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality

    func test_distanceText_returnsFormattedMiles() {
        XCTAssertEqual(viewModel.distanceText, String(format: "%.1f mi", 900 / 1609.34))
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

    func test_loggedPointCount_returnsPathCount() {
        XCTAssertEqual(viewModel.loggedPointCount, trip.path.count)
    }

    func test_startCoordinate_returnsFirstPathPoint() {
        XCTAssertEqual(viewModel.startCoordinate.latitude, 10)
        XCTAssertEqual(viewModel.startCoordinate.longitude, 10)
    }

    func test_endCoordinate_returnsLastPathPoint() {
        XCTAssertEqual(viewModel.endCoordinate.latitude, 12)
        XCTAssertEqual(viewModel.endCoordinate.longitude, 12)
    }

    // MARK: - Advanced Functionality

    func test_loggedPointCount_dynamicUpdate() {
        var mutableTrip = trip!
        mutableTrip.path.append(CoordinateModel(latitude: 13, longitude: 13))
        viewModel = TripDetailViewModel(trip: mutableTrip)
        XCTAssertEqual(viewModel.loggedPointCount, 4)
    }

    func test_startCoordinate_withOnePoint_returnsThatPoint() {
        let path = [CoordinateModel(latitude: 5, longitude: 6)]
        let singlePointTrip = MockTripSessionModel.make(path: path)
        let vm = TripDetailViewModel(trip: singlePointTrip)
        XCTAssertEqual(vm.startCoordinate.latitude, 5)
        XCTAssertEqual(vm.startCoordinate.longitude, 6)
        XCTAssertEqual(vm.endCoordinate.latitude, 5)
        XCTAssertEqual(vm.endCoordinate.longitude, 6)
    }

    // MARK: - Edge Cases

    func test_startCoordinate_whenNoPath_returnsDefaultZero() {
        let emptyPathTrip = MockTripSessionModel.make(path: [])
        let vm = TripDetailViewModel(trip: emptyPathTrip)
        XCTAssertEqual(vm.startCoordinate.latitude, 0)
        XCTAssertEqual(vm.startCoordinate.longitude, 0)
    }

    func test_endCoordinate_whenNoPath_returnsDefaultZero() {
        let emptyPathTrip = MockTripSessionModel.make(path: [])
        let vm = TripDetailViewModel(trip: emptyPathTrip)
        XCTAssertEqual(vm.endCoordinate.latitude, 0)
        XCTAssertEqual(vm.endCoordinate.longitude, 0)
    }
}
