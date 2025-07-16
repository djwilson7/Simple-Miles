//
//  PermissionsService.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine
import CoreLocation
import UIKit

protocol PermissionsServicing {
    func currentLocationStatus() -> CLAuthorizationStatus
    func isBackgroundRefreshAvailable() -> Bool
    func requestLocationAuthorization()
}

final class PermissionsService: NSObject, PermissionsServicing {
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = nil // delegate is optional at service level
    }

    func currentLocationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    func isBackgroundRefreshAvailable() -> Bool {
        return UIApplication.shared.backgroundRefreshStatus == .available
    }

    func requestLocationAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
}
