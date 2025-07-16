//
//  MockSettingsStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

// MockSettingsStore.swift
import Foundation
@testable import SimpleMiles

final class MockSettingsStore: SettingsStoring {
    private var storage: [String: Any] = [:]

    func getBool(_ key: SettingsKey, default defaultValue: Bool) -> Bool {
        return storage[key.rawValue] as? Bool ?? defaultValue
    }

    func getString(_ key: SettingsKey, default defaultValue: String) -> String {
        return storage[key.rawValue] as? String ?? defaultValue
    }

    func getEnum<T>(_ key: SettingsKey, default defaultValue: T) -> T where T : RawRepresentable, T.RawValue == String {
        guard let raw = storage[key.rawValue] as? String, let value = T(rawValue: raw) else {
            return defaultValue
        }
        return value
    }

    func set<T>(_ key: SettingsKey, value: T) {
        storage[key.rawValue] = value
    }

    // Convenience accessors for test assertions
    func rawValue(for key: SettingsKey) -> Any? {
        return storage[key.rawValue]
    }
}
