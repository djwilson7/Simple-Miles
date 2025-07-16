//
//  SettingsKeysTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class SettingsKeysTests: XCTestCase {
    func testAllKeysAreUnique() {
        let allKeys = Set(SettingsKey.allCases.map(\.rawValue))
        XCTAssertEqual(allKeys.count, SettingsKey.allCases.count, "Duplicate keys detected in SettingsKey enum.")
    }
}
