//
//  PrivacyConsentLevelsTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class PrivacyConsentLevelTests: XCTestCase {
    func testRawValueInitialization() {
        XCTAssertEqual(PrivacyConsentLevel(rawValue: "none"), PrivacyConsentLevel.none)
        XCTAssertEqual(PrivacyConsentLevel(rawValue: "diagnostics"), PrivacyConsentLevel.diagnostics)
        XCTAssertEqual(PrivacyConsentLevel(rawValue: "fullSharing"), PrivacyConsentLevel.fullSharing)
    }

    func testAllCasesCount() {
        XCTAssertEqual(PrivacyConsentLevel.allCases.count, 3)
    }
}
