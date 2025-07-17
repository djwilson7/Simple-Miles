//
//  SettingsStoreTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

// SettingsStoreTests.swift

import XCTest
@testable import SimpleMiles

final class SettingsStoreTests: XCTestCase {
    private var store: SettingsStore!
    private var testDefaults: UserDefaults!
    private let suiteName = "com.simplemiles.test.settings"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: suiteName)
        testDefaults.removePersistentDomain(forName: suiteName)
        store = SettingsStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        store = nil
        super.tearDown()
    }

    func test_getBool_returnsDefaultWhenUnset() {
        XCTAssertFalse(store.getBool(.autoStartEnabled, default: false))
        XCTAssertTrue(store.getBool(.autoStartEnabled, default: true))
    }

    func test_set_and_getBool_returnsStoredValue() {
        store.set(.autoStartEnabled, value: true)
        XCTAssertTrue(store.getBool(.autoStartEnabled, default: false))
    }

    func test_getString_returnsStoredValue() {
        store.set(.defaultExportFileNamePrefix, value: "Test_")
        let value = store.getString(.defaultExportFileNamePrefix, default: "Fallback")
        XCTAssertEqual(value, "Test_")
    }

    func test_getEnum_returnsValidEnum_whenStored() {
        store.set(.defaultTripType, value: TripType.business.rawValue)
        let value: TripType = store.getEnum(.defaultTripType, default: .unclassified)
        XCTAssertEqual(value, .business)
    }

    func test_getEnum_returnsDefault_whenInvalidOrMissing() {
        let value: TripType = store.getEnum(.defaultTripType, default: .unclassified)
        XCTAssertEqual(value, .unclassified)
    }
}
