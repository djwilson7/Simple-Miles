//
//  TripClassificationViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TripClassificationViewModelTests: XCTestCase {

    func testUpdateClassificationChangesTripType() {
        let trip = TripSessionModel(tripType: .unclassified)
        let mockStore = MockTripSessionStore()
        let sut = TripClassificationViewModel(trip: trip, store: mockStore)

        sut.updateClassification(to: .business)

        XCTAssertEqual(sut.trip.tripType, .business)
        XCTAssertEqual(mockStore.updatedModels.first?.tripType, .business)
    }

    func testIsClassifiedReturnsTrueWhenMatching() {
        let trip = TripSessionModel(tripType: .personal)
        let sut = TripClassificationViewModel(trip: trip)

        XCTAssertTrue(sut.isClassified(as: .personal))
        XCTAssertFalse(sut.isClassified(as: .business))
    }

    func testCurrentClassificationLabelReturnsExpectedRawValue() {
        let trip = TripSessionModel(tripType: .unclassified)
        let sut = TripClassificationViewModel(trip: trip)

        XCTAssertEqual(sut.currentClassificationLabel(), "Unclassified")
    }
}
