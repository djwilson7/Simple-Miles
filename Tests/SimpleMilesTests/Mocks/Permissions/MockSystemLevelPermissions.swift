//
//  MockSystemLevelPermissions.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
import CoreLocation
@testable import SimpleMiles

final class MockSystemLevelPermissions: SystemLevelPermissionsProtocol {
    var locationStatus: CLAuthorizationStatus = .authorizedAlways
    var backgroundRefreshEnabled: Bool = true

    private(set) var didRequestPermission = false
    private(set) var didRefreshStatus = false

    func requestLocationPermission() {
        didRequestPermission = true
    }

    func refreshStatus() {
        didRefreshStatus = true
    }
}
