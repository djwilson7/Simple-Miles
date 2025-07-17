//
//  PermissionsViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

// MARK: - PermissionsViewModelTests.swift

import XCTest
@testable import SimpleMiles

final class PermissionsViewModelTests: XCTestCase {
    private var viewModel: PermissionsViewModel!
    private var mockSystem: MockSystemLevelPermissions!
    private var mockPrivacy: MockDataPrivacyPermissions!

    override func setUp() {
        super.setUp()
        mockSystem = MockSystemLevelPermissions()
        mockPrivacy = MockDataPrivacyPermissions()
        viewModel = PermissionsViewModel(system: mockSystem, privacy: mockPrivacy)
    }

    override func tearDown() {
        viewModel = nil
        mockSystem = nil
        mockPrivacy = nil
        super.tearDown()
    }

    func test_refreshSystemStatus_callsRefreshStatus() {
        viewModel.refreshSystemStatus()
        XCTAssertTrue(mockSystem.didRefreshStatus)
    }

    func test_requestLocationAccess_callsRequestLocationPermission() {
        viewModel.requestLocationAccess()
        XCTAssertTrue(mockSystem.didRequestPermission)
    }

    func test_consentLevel_binding_readsFromPrivacyModel() {
        mockPrivacy.consentLevel = .fullSharing
        XCTAssertEqual(viewModel.privacy.consentLevel, .fullSharing)
    }
}
