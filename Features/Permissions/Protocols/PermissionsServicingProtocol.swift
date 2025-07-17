//
//  PermissionsServicingProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import CoreLocation

protocol PermissionsServicingProtocol {
    func currentLocationStatus() -> CLAuthorizationStatus
    func isBackgroundRefreshAvailable() -> Bool
    func requestLocationAuthorization()
}
