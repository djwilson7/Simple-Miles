//
//  PermissionsService.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import CoreLocation
import UIKit

final class PermissionsService: NSObject, PermissionsServicingProtocol {
    private let locationManager: CLLocationManager
    private let app: ApplicationStateReadingProtocol

    init(
        locationManager: CLLocationManager = CLLocationManager(),
        app: ApplicationStateReadingProtocol
    ) {
        print("[PermissionsService] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.locationManager = locationManager
        self.app = app
        super.init()
    }

    func currentLocationStatus() -> CLAuthorizationStatus {
        print("[PermissionsService] currentLocationStatus triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return locationManager.authorizationStatus
    }

    func isBackgroundRefreshAvailable() -> Bool {
        print("[PermissionsService] isBackgroundRefreshAvailable triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return app.backgroundRefreshStatus == .available
    }

    func requestLocationAuthorization() {
        print("[PermissionsService] requestLocationAuthorization triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        locationManager.requestAlwaysAuthorization()
    }
}
