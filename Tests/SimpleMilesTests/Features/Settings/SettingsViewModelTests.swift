//  SettingsViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: initialization with dependency-injected settings models, published property mutation,
//  propagation of changes, and contract validation for all settings domains (recording, display, export, classification).
//  Suite guarantees correct value mapping, mutation, and real-time reflection for both standard and alternate settings flows.

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

    // MARK: - Basic Functionality

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

    // MARK: - Advanced Functionality

    func test_settingPublishedProperties_replacesPublishedObjects() {
        let newRecording = MockRecordingSettings()
        let newDisplay = MockDisplaySettings()
        let newExport = MockExportSettings()
        let newClassification = MockClassificationSettings()
        viewModel.recording = newRecording
        viewModel.display = newDisplay
        viewModel.export = newExport
        viewModel.classification = newClassification

        XCTAssertTrue(viewModel.recording === newRecording)
        XCTAssertTrue(viewModel.display === newDisplay)
        XCTAssertTrue(viewModel.export === newExport)
        XCTAssertTrue(viewModel.classification === newClassification)
    }

    // MARK: - Edge Cases

    func test_settings_mutation_edgeCases() {
        // Simulate extreme edge settings and verify mapping still holds.
        viewModel.display.timeFormat = .twelveHour
        viewModel.export.defaultExportFormat = .json
        viewModel.recording.autoStartEnabled = true
        viewModel.classification.defaultTripType = .unclassified

        XCTAssertEqual(viewModel.display.timeFormat, .twelveHour)
        XCTAssertEqual(viewModel.export.defaultExportFormat, .json)
        XCTAssertTrue(viewModel.recording.autoStartEnabled)
        XCTAssertEqual(viewModel.classification.defaultTripType, .unclassified)
    }
}
