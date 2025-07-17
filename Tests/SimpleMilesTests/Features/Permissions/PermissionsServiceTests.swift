//
//  PermissionsServiceTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
// PermissionsServiceTests.swift

// PermissionsServiceTests.swift

import XCTest
@testable import SimpleMiles
import CoreLocation
import UIKit

final class PermissionsServiceTests: XCTestCase {
    private var mockLocationManager: MockLocationManager!
    private var mockAppState: MockAppStateReader!
    private var service: PermissionsServicingProtocol!

    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        mockAppState = MockAppStateReader()
        service = PermissionsService(
            locationManager: mockLocationManager,
            app: mockAppState
        )
    }

    override func tearDown() {
        service = nil
        mockLocationManager = nil
        mockAppState = nil
        super.tearDown()
    }

    func test_currentLocationStatus_returnsMockedValue() {
        mockLocationManager.mockAuthorizationStatus = .denied
        XCTAssertEqual(service.currentLocationStatus(), .denied)
    }

    func test_isBackgroundRefreshAvailable_reflectsMockedStatus() {
        mockAppState.backgroundRefreshStatus = .restricted
        XCTAssertFalse(service.isBackgroundRefreshAvailable())
    }

    func test_requestLocationAuthorization_triggersRequestFlag() {
        service.requestLocationAuthorization()
        XCTAssertTrue(mockLocationManager.didRequestAlwaysAuthorization)
    }
}
