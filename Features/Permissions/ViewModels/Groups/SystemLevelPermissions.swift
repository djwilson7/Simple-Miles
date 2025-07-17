//
//  SystemLevelPermissions.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine
import CoreLocation
import UIKit

final class SystemLevelPermissions: NSObject, ObservableObject, SystemLevelPermissionsProtocol {
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var backgroundRefreshEnabled: Bool = true // assumed enabled unless overridden

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationStatus = locationManager.authorizationStatus
        backgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
    }

    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func refreshStatus() {
        locationStatus = locationManager.authorizationStatus
        backgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
    }
}

extension SystemLevelPermissions: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
    }
}
