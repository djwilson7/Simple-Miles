//
//  TripDetailViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TripDetailViewModelTests: XCTestCase {

    func testDistanceTextFormatsMilesCorrectly() {
        let trip = TripSessionModel(distance: 1609.34) // 1 mile
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.distanceText, "1.0 mi")
    }

    func testDurationTextFormatsMinutesAndSeconds() {
        let start = Date()
        let end = start.addingTimeInterval(125)
        let trip = TripSessionModel(startTime: start, endTime: end)
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.durationText, "2m 5s")
    }

    func testStartDateTextReturnsFormattedDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let now = dateFormatter.date(from: "2025-07-14") else {
            XCTFail("Failed to generate test date")
            return
        }

        let trip = TripSessionModel(startTime: now)
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertTrue(sut.startDateText.contains("2025"), "Expected formatted year in startDateText")
    }


    func testEndDateTextReturnsInProgressIfNil() {
        var trip = TripSessionModel()
        trip.endTime = nil
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.endDateText, "In Progress")
    }

    func testSegmentCountReturnsCorrectValue() {
        let segment = TripSegmentModel.mock()
        let trip = TripSessionModel(segments: [segment, segment])
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.segmentCount, 2)
    }

    func testStartAndEndCoordinatesFallbackToZero() {
        let trip = TripSessionModel(segments: [])
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.startCoordinate.latitude, 0)
        XCTAssertEqual(sut.endCoordinate.longitude, 0)
    }
    
    func testDistanceTextFormatsZeroAsZeroMiles() {
        let trip = TripSessionModel(distance: 0)
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.distanceText, "0.0 mi")
    }

    func testDurationTextFormatsLongTripCorrectly() {
        let start = Date()
        let end = start.addingTimeInterval(3 * 3600 + 45 * 60 + 10) // 3h 45m 10s
        let trip = TripSessionModel(startTime: start, endTime: end)
        let sut = TripDetailViewModel(trip: trip)

        let output = sut.durationText
        XCTAssertTrue(output.contains("225m") || output.contains("3h"), "Expected duration to represent a long trip")
    }

    func testStartAndEndDatesAreDifferentForMultiDayTrip() {
        let start = Date(timeIntervalSince1970: 1_735_000_000) // Jan 2025
        let end = start.addingTimeInterval(60 * 60 * 24 * 3)   // +3 days
        let trip = TripSessionModel(startTime: start, endTime: end)
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertNotEqual(sut.startDateText, sut.endDateText)
    }

    func testCoordinateFallbackIsSafeWhenFirstOrLastSegmentIsInvalid() {
        let segment = TripSegmentModel.mock(
            startCoordinate: CoordinateModel(latitude: 0, longitude: 0),
            endCoordinate: CoordinateModel(latitude: 0, longitude: 0)
        )
        let trip = TripSessionModel(segments: [segment])
        let sut = TripDetailViewModel(trip: trip)

        XCTAssertEqual(sut.startCoordinate.latitude, 0)
        XCTAssertEqual(sut.endCoordinate.longitude, 0)
    }

}
