//
//  ClassificationSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class ClassificationSettings: ObservableObject {
    @Published var defaultTripType: TripType {
        didSet { store.set(.defaultTripType, value: defaultTripType.rawValue) }
    }

    private let store: SettingsStoring

    init(store: SettingsStoring) {
        self.store = store
        defaultTripType = store.getEnum(.defaultTripType, default: .unclassified)
    }
}
