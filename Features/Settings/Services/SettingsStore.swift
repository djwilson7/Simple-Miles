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
    private let defaults: UserDefaults

    static let shared = SettingsStore()

    init(defaults: UserDefaults = .standard) {
        print("[SettingsStore] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.defaults = defaults
    }

    func getBool(_ key: SettingsKey, default defaultValue: Bool) -> Bool {
        print("[SettingsStore] getBool triggered for key: \(key)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return defaults.object(forKey: key.rawValue) as? Bool ?? defaultValue
    }

    func getString(_ key: SettingsKey, default defaultValue: String) -> String {
        print("[SettingsStore] getString triggered for key: \(key)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return defaults.string(forKey: key.rawValue) ?? defaultValue
    }

    func getEnum<T: RawRepresentable>(_ key: SettingsKey, default defaultValue: T) -> T where T.RawValue == String {
        print("[SettingsStore] getEnum triggered for key: \(key)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let raw = defaults.string(forKey: key.rawValue),
              let value = T(rawValue: raw) else {
            print("[SettingsStore] getEnum fallback to default for key: \(key)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return defaultValue
        }
        return value
    }

    func set<T>(_ key: SettingsKey, value: T) {
        print("[SettingsStore] set triggered for key: \(key), value: \(value)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        defaults.set(value, forKey: key.rawValue)
    }
}
