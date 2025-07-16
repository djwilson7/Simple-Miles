//
//  SettingsStoreTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class SettingsStoreTests: XCTestCase {
    var store: SettingsStore!

    override func setUp() {
        super.setUp()
        store = SettingsStore.shared
    }

    func testSetAndGetBool() {
        let key: SettingsKey = .autoStartEnabled
        store.set(key, value: true)
        XCTAssertTrue(store.getBool(key, default: false))
    }

    func testSetAndGetString() {
        let key: SettingsKey = .defaultExportFileNamePrefix
        store.set(key, value: "TestPrefix_")
        XCTAssertEqual(store.getString(key, default: ""), "TestPrefix_")
    }

    func testSetAndGetEnum_valid() {
        let key: SettingsKey = .distanceUnit
        store.set(key, value: DistanceUnit.kilometers.rawValue)
        let result: DistanceUnit = store.getEnum(key, default: .miles)
        XCTAssertEqual(result, .kilometers)
    }

    func testGetEnum_invalidFallsBackToDefault() {
        let key: SettingsKey = .timeFormat
        store.set(key, value: "invalid_raw_value")
        let result: TimeFormat = store.getEnum(key, default: .twelveHour)
        XCTAssertEqual(result, .twelveHour)
    }

    func testGetEnum_whenNoValue_returnsDefault() {
        let key: SettingsKey = .motionSensitivity
        let result: MotionSensitivityLevel = store.getEnum(key, default: .medium)
        XCTAssertEqual(result, .medium)
    }
}

