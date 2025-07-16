//
//  RecordingSettingsTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import Combine
@testable import SimpleMiles


final class RecordingSettingsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    
    func testDefaultsLoadCorrectly() {
        let store = MockSettingsStore()
        let settings = RecordingSettings(store: store)

        XCTAssertTrue(settings.autoStartEnabled)
        XCTAssertTrue(settings.autoStopEnabled)
        XCTAssertEqual(settings.motionSensitivity, .medium)
    }

    func testSettingValuesArePersisted() {
        let store = MockSettingsStore()
        let settings = RecordingSettings(store: store)

        settings.autoStartEnabled = false
        settings.autoStopEnabled = false
        settings.motionSensitivity = .high

        XCTAssertEqual(store.getBool(.autoStartEnabled, default: true), false)
        XCTAssertEqual(store.getBool(.autoStopEnabled, default: true), false)
        XCTAssertEqual(store.getEnum(.motionSensitivity, default: .low), MotionSensitivityLevel.high)
    }
    
    func testPublishesChanges() {
        let store = MockSettingsStore()
        let settings = RecordingSettings(store: store)

        let expectation = expectation(description: "Settings should publish change")
        settings.objectWillChange
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        settings.autoStartEnabled.toggle()
        wait(for: [expectation], timeout: 0.2)
    }

    func testHandlesCorruptedEnumValue() {
        let store = MockSettingsStore()
        store.set(.motionSensitivity, value: "not_valid")
        let settings = RecordingSettings(store: store)
        XCTAssertEqual(settings.motionSensitivity, .medium)
    }

    func testHandlesInvalidEnumValues() {
        let store = MockSettingsStore()
        store.set(.defaultTripType, value: "nonsense")
        let settings = ClassificationSettings(store: store)
        XCTAssertEqual(settings.defaultTripType, .unclassified)
    }
}
