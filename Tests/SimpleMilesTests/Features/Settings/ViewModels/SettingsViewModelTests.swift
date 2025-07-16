//
//  SettingsViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class SettingsViewModelTests: XCTestCase {
    func testInitializationInjectsAllGroups() {
        let store = MockSettingsStore()
        let viewModel = SettingsViewModel(store: store)

        XCTAssertNotNil(viewModel.recording)
        XCTAssertNotNil(viewModel.display)
        XCTAssertNotNil(viewModel.export)
        XCTAssertNotNil(viewModel.classification)
    }

    func testChangesPropagateToStore() {
        let store = MockSettingsStore()
        let viewModel = SettingsViewModel(store: store)

        viewModel.recording.autoStartEnabled = false
        viewModel.display.distanceUnit = .kilometers
        viewModel.export.includeRawCoordinates = true
        viewModel.classification.defaultTripType = .business

        let autoStart: Bool = store.getBool(.autoStartEnabled, default: true)
        let unit: DistanceUnit = store.getEnum(.distanceUnit, default: .miles)
        let coords: Bool = store.getBool(.includeRawCoordinates, default: false)
        let tripType: TripType = store.getEnum(.defaultTripType, default: .unclassified)

        XCTAssertFalse(autoStart)
        XCTAssertEqual(unit, .kilometers)
        XCTAssertTrue(coords)
        XCTAssertEqual(tripType, .business)
    }
}
