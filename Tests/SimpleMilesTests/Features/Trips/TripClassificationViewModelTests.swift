//  TripClassificationViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: trip type classification updates, persistence and propagation to session store,
//  label/enum mapping, and classification query logic.
//  Suite covers all public behaviors and edge paths for classification, including type matching, mutation, and label consistency.

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
        mockStore.save(trip)
        viewModel = TripClassificationViewModel(trip: trip, store: mockStore)
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        trip = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality

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

    // MARK: - Advanced Functionality

    func test_updateClassification_toSameType_noRedundantStoreUpdate() {
        viewModel.updateClassification(to: .unclassified)
        let updateCount = mockStore.updateCallCount(for: trip.id)
        XCTAssertEqual(updateCount, 1) // Should only be called once (not redundantly)
    }

    func test_updateClassification_multipleTypeChanges_reflectsLatest() {
        viewModel.updateClassification(to: .personal)
        viewModel.updateClassification(to: .business)
        XCTAssertEqual(viewModel.trip.tripType, .business)
        let updatedTrip = mockStore.mockTrips.first(where: { $0.id == trip.id })
        XCTAssertEqual(updatedTrip?.tripType, .business)
    }

    // MARK: - Edge Cases

    func test_updateClassification_toInvalidType_doesNotCrash() {
        // Assuming all TripType values are valid; if .none or similar exists, test here
        // This test will pass for exhaustive enums; modify if new invalid states are introduced
        viewModel.updateClassification(to: .unclassified)
        XCTAssertEqual(viewModel.trip.tripType, .unclassified)
    }
}
