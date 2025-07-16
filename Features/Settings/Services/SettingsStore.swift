//
//  SettingsStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

protocol SettingsStoring {
    func getBool(_ key: SettingsKey, default defaultValue: Bool) -> Bool
    func getString(_ key: SettingsKey, default defaultValue: String) -> String
    func getEnum<T: RawRepresentable>(_ key: SettingsKey, default defaultValue: T) -> T where T.RawValue == String
    func set<T>(_ key: SettingsKey, value: T)
}

final class SettingsStore: SettingsStoring {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard

    func getBool(_ key: SettingsKey, default defaultValue: Bool) -> Bool {
        defaults.object(forKey: key.rawValue) as? Bool ?? defaultValue
    }

    func getString(_ key: SettingsKey, default defaultValue: String) -> String {
        defaults.string(forKey: key.rawValue) ?? defaultValue
    }

    func getEnum<T: RawRepresentable>(_ key: SettingsKey, default defaultValue: T) -> T where T.RawValue == String {
        guard let raw = defaults.string(forKey: key.rawValue),
              let value = T(rawValue: raw) else {
            return defaultValue
        }
        return value
    }

    func set<T>(_ key: SettingsKey, value: T) {
        defaults.set(value, forKey: key.rawValue)
    }
}
