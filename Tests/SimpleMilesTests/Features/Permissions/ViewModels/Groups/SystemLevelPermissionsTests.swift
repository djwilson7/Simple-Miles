//
//  SystemLevelPermissions.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import Combine
import CoreLocation
@testable import SimpleMiles

final class SystemLevelPermissionsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testInitialStatusMatchesManager() {
        let viewModel = SystemLevelPermissions()
        let expected = CLLocationManager().authorizationStatus
        XCTAssertEqual(viewModel.locationStatus, expected)
    }

    func testPublishesOnChange() {
        let viewModel = SystemLevelPermissions()
        let expectation = expectation(description: "Permission change should publish")
        expectation.expectedFulfillmentCount = 1

        viewModel.objectWillChange
            .dropFirst() // avoids capturing the initial emission on subscription
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewModel.refreshStatus()
        wait(for: [expectation], timeout: 0.5)
    }
}
