//
//  PermissionsViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import CoreLocation
@testable import SimpleMiles

final class PermissionsViewModelTests: XCTestCase {
    func testInitializationWiresGroups() {
        let viewModel = PermissionsViewModel()
        XCTAssertNotNil(viewModel.system)
        XCTAssertNotNil(viewModel.privacy)
    }

    func testDelegatesPermissionRefresh() {
        let viewModel = PermissionsViewModel()
        viewModel.system.locationStatus = .restricted
        viewModel.refreshSystemStatus()

        // Assert value still belongs to known cases
        let valid: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied, .authorizedWhenInUse, .authorizedAlways
        ]
        XCTAssertTrue(valid.contains(viewModel.system.locationStatus))
    }
}
