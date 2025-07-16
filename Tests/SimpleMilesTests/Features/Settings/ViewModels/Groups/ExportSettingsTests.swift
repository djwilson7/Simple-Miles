//
//  ExportSettingsTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import Combine
@testable import SimpleMiles

final class ExportSettingsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    
    func testDefaultsLoadCorrectly() {
        let store = MockSettingsStore()
        let settings = ExportSettings(store: store)

        XCTAssertEqual(settings.defaultExportFormat, .csv)
        XCTAssertFalse(settings.includeRawCoordinates)
        XCTAssertEqual(settings.defaultExportFileNamePrefix, "MilesExport_")
    }

    func testSettingValuesArePersisted() {
        let store = MockSettingsStore()
        let settings = ExportSettings(store: store)

        settings.defaultExportFormat = .json
        settings.includeRawCoordinates = true
        settings.defaultExportFileNamePrefix = "Export_"

        XCTAssertEqual(store.getEnum(.defaultExportFormat, default: .csv), ExportFormat.json)
        XCTAssertTrue(store.getBool(.includeRawCoordinates, default: false))
        XCTAssertEqual(store.getString(.defaultExportFileNamePrefix, default: ""), "Export_")
    }
    
    func testPublishesChanges() {
        let store = MockSettingsStore()
        let settings = ExportSettings(store: store)

        let expectation = expectation(description: "Change should publish")
        settings.objectWillChange
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        settings.includeRawCoordinates.toggle()
        wait(for: [expectation], timeout: 0.2)
    }

    func testHandlesCorruptedEnumValues() {
        let store = MockSettingsStore()
        store.set(.defaultExportFormat, value: "broken")
        let settings = ExportSettings(store: store)
        XCTAssertEqual(settings.defaultExportFormat, .csv)
    }
}
