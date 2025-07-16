//
//  DisplaySettignsTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import Combine
@testable import SimpleMiles

final class DisplaySettingsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    
    func testDefaultsLoadCorrectly() {
        let store = MockSettingsStore()
        let settings = DisplaySettings(store: store)

        XCTAssertEqual(settings.distanceUnit, .miles)
        XCTAssertEqual(settings.timeFormat, .twelveHour)
    }

    func testSettingValuesArePersisted() {
        let store = MockSettingsStore()
        let settings = DisplaySettings(store: store)

        settings.distanceUnit = .kilometers
        settings.timeFormat = .twentyFourHour

        XCTAssertEqual(store.getEnum(.distanceUnit, default: .miles), DistanceUnit.kilometers)
        XCTAssertEqual(store.getEnum(.timeFormat, default: .twelveHour), TimeFormat.twentyFourHour)
    }
    
    func testPublishesChanges() {
        let store = MockSettingsStore()
        let settings = DisplaySettings(store: store)

        let expectation = expectation(description: "Change should publish")
        settings.objectWillChange
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        settings.distanceUnit = .kilometers
        wait(for: [expectation], timeout: 0.2)
    }

    func testHandlesInvalidEnumValues() {
        let store = MockSettingsStore()
        store.set(.timeFormat, value: "bad_value")
        let settings = DisplaySettings(store: store)
        XCTAssertEqual(settings.timeFormat, .twelveHour)
    }
}
