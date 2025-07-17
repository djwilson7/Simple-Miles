//
//  DisplaySettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class DisplaySettings: DisplaySettingsProtocol {
    @Published var distanceUnit: DistanceUnit {
        didSet { store.set(.distanceUnit, value: distanceUnit.rawValue) }
    }

    @Published var timeFormat: TimeFormat {
        didSet { store.set(.timeFormat, value: timeFormat.rawValue) }
    }

    private let store: SettingsStoring

    init(store: SettingsStoring) {
        self.store = store
        distanceUnit = store.getEnum(.distanceUnit, default: .miles)
        timeFormat = store.getEnum(.timeFormat, default: .twelveHour)
    }
}
