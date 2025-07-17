//
//  SettingsViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class SettingsViewModelTests: XCTestCase {
    private var viewModel: SettingsViewModel!
    private var mockRecording: MockRecordingSettings!
    private var mockDisplay: MockDisplaySettings!
    private var mockExport: MockExportSettings!
    private var mockClassification: MockClassificationSettings!

    override func setUp() {
        super.setUp()
        mockRecording = MockRecordingSettings()
        mockDisplay = MockDisplaySettings()
        mockExport = MockExportSettings()
        mockClassification = MockClassificationSettings()

        viewModel = SettingsViewModel(
            recording: mockRecording,
            display: mockDisplay,
            export: mockExport,
            classification: mockClassification
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRecording = nil
        mockDisplay = nil
        mockExport = nil
        mockClassification = nil
        super.tearDown()
    }

    func test_settingsViewModel_initializesWithInjectedValues() {
        XCTAssertTrue(viewModel.recording.autoStartEnabled)
        XCTAssertEqual(viewModel.display.timeFormat, .twentyFourHour)
        XCTAssertEqual(viewModel.export.defaultExportFormat, .csv)
        XCTAssertEqual(viewModel.classification.defaultTripType, .business)
    }

    func test_settings_canMutateAndReflectChanges() {
        viewModel.recording.autoStartEnabled = false
        viewModel.display.distanceUnit = .kilometers
        viewModel.export.includeRawCoordinates = false
        viewModel.classification.defaultTripType = .personal

        XCTAssertFalse(viewModel.recording.autoStartEnabled)
        XCTAssertEqual(viewModel.display.distanceUnit, .kilometers)
        XCTAssertFalse(viewModel.export.includeRawCoordinates)
        XCTAssertEqual(viewModel.classification.defaultTripType, .personal)
    }
}
