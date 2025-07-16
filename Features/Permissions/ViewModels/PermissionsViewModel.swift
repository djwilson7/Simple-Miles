//
//  PermissionsViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class PermissionsViewModel: ObservableObject {
    @Published var system: SystemLevelPermissions
    @Published var privacy: DataPrivacyPermissions

    init(
        system: SystemLevelPermissions = SystemLevelPermissions(),
        privacy: DataPrivacyPermissions = DataPrivacyPermissions()
    ) {
        self.system = system
        self.privacy = privacy
    }

    func refreshSystemStatus() {
        system.refreshStatus()
    }

    func requestLocationAccess() {
        system.requestLocationPermission()
    }
}
