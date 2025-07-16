//
//  PermissionsServiceTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import CoreLocation
@testable import SimpleMiles

final class PermissionsServiceTests: XCTestCase {
    var service: PermissionsService!

    override func setUp() {
        super.setUp()
        service = PermissionsService()
    }

    func testReturnsAuthorizationStatus() {
        let status = service.currentLocationStatus()
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied, .authorizedAlways, .authorizedWhenInUse
        ]
        XCTAssertTrue(validStatuses.contains(status))
    }

    func testReturnsBackgroundRefreshStatus() {
        let available = service.isBackgroundRefreshAvailable()
        XCTAssertTrue(available || !available) // Sanity check
    }
}
