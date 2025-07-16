//
//  DataPrivacyPermissions.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class DataPrivacyPermissions: ObservableObject {
    @Published var consentLevel: PrivacyConsentLevel {
        didSet { store.set(.privacyConsentLevel, value: consentLevel.rawValue) }
    }

    private let store: SettingsStoring

    init(store: SettingsStoring = SettingsStore.shared) {
        self.store = store
        self.consentLevel = store.getEnum(.privacyConsentLevel, default: .none)
    }
}
