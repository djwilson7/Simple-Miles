//
//  MotionSensitivityLevelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class MotionSensitivityLevelTests: XCTestCase {
    func testRawValueRoundTrip() {
        XCTAssertEqual(MotionSensitivityLevel(rawValue: "low"), .low)
        XCTAssertEqual(MotionSensitivityLevel(rawValue: "medium"), .medium)
        XCTAssertEqual(MotionSensitivityLevel(rawValue: "high"), .high)
    }

    func testAllCasesCount() {
        XCTAssertEqual(MotionSensitivityLevel.allCases.count, 3)
    }
}
