//
//  PermissionsViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class PermissionsViewModel: ObservableObject {
    @Published var system: SystemLevelPermissionsProtocol
    @Published var privacy: DataPrivacyPermissionsProtocol

    init(
        system: SystemLevelPermissionsProtocol = SystemLevelPermissions(),
        privacy: DataPrivacyPermissionsProtocol = DataPrivacyPermissions()
    ) {
        self.system = system
        self.privacy = privacy
    }

    func refreshSystemStatus() {
        print("[PermissionsViewModel] refreshSystemStatus triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        system.refreshStatus()
    }

    func requestLocationAccess() {
        print("[PermissionsViewModel] requestLocationAccess triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        system.requestLocationPermission()
    }
}
