//
//  DistanceUnitTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

// DistanceUnitTests.swift
import XCTest
@testable import SimpleMiles

final class DistanceUnitTests: XCTestCase {
    func testRawValueRoundTrip() {
        XCTAssertEqual(DistanceUnit(rawValue: "miles"), .miles)
        XCTAssertEqual(DistanceUnit(rawValue: "kilometers"), .kilometers)
    }

    func testAllCasesCount() {
        XCTAssertEqual(DistanceUnit.allCases.count, 2)
    }
}
