//
//  MockLocationManager.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import CoreLocation

final class MockLocationManager: CLLocationManager {
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var didRequestAlwaysAuthorization = false

    override var authorizationStatus: CLAuthorizationStatus {
        return mockAuthorizationStatus
    }

    override func requestAlwaysAuthorization() {
        didRequestAlwaysAuthorization = true
    }
}
