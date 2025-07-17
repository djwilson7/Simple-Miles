//
//  TripClassificationViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

// MARK: - TripClassificationViewModelTests.swift

import XCTest
@testable import SimpleMiles

final class TripClassificationViewModelTests: XCTestCase {
    private var viewModel: TripClassificationViewModel!
    private var mockStore: MockTripSessionStore!
    private var trip: TripSessionModel!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
        trip = MockTripSessionModel.make(tripType: .unclassified)
        mockStore.save(trip) // Seed the store
        viewModel = TripClassificationViewModel(trip: trip, store: mockStore)
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        trip = nil
        super.tearDown()
    }

    func test_updateClassification_changesTypeAndUpdatesStore() {
        viewModel.updateClassification(to: .business)

        XCTAssertEqual(viewModel.trip.tripType, .business)

        let updatedTrip = mockStore.mockTrips.first(where: { $0.id == trip.id })
        XCTAssertEqual(updatedTrip?.tripType, .business)
    }

    func test_currentClassificationLabel_returnsRawValue() {
        XCTAssertEqual(viewModel.currentClassificationLabel(), TripType.unclassified.rawValue)
    }

    func test_isClassified_returnsTrueForMatch() {
        XCTAssertTrue(viewModel.isClassified(as: .unclassified))
    }

    func test_isClassified_returnsFalseForNonMatch() {
        XCTAssertFalse(viewModel.isClassified(as: .personal))
    }
}
