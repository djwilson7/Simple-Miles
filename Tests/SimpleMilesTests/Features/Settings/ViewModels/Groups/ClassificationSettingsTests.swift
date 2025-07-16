//
//  ClassificationSettingsTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class ClassificationSettingsTests: XCTestCase {
    func testDefaultsLoadCorrectly() {
        let store = MockSettingsStore()
        let settings = ClassificationSettings(store: store)

        XCTAssertEqual(settings.defaultTripType, .unclassified)
    }

    func testSettingValuesArePersisted() {
        let store = MockSettingsStore()
        let settings = ClassificationSettings(store: store)

        settings.defaultTripType = .business
        XCTAssertEqual(store.getEnum(.defaultTripType, default: .personal), TripType.business)
    }
}
