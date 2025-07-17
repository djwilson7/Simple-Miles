//
//  MockSettingsStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockSettingsStore: SettingsStoring {
    private var storage: [SettingsKey: Any] = [:]

    func getBool(_ key: SettingsKey, default defaultValue: Bool) -> Bool {
        return storage[key] as? Bool ?? defaultValue
    }

    func getString(_ key: SettingsKey, default defaultValue: String) -> String {
        return storage[key] as? String ?? defaultValue
    }

    func getEnum<T>(_ key: SettingsKey, default defaultValue: T) -> T where T : RawRepresentable, T.RawValue == String {
        guard let raw = storage[key] as? String,
              let value = T(rawValue: raw) else {
            return defaultValue
        }
        return value
    }

    func set<T>(_ key: SettingsKey, value: T) {
        storage[key] = value
    }
}
