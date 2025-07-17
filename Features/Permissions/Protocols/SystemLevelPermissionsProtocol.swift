//
//  SystemLevelPermissionsProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
import CoreLocation

protocol SystemLevelPermissionsProtocol: AnyObject {
    var locationStatus: CLAuthorizationStatus { get set }
    var backgroundRefreshEnabled: Bool { get set }

    func requestLocationPermission()
    func refreshStatus()
}
