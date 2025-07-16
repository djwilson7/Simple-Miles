//
//  TimeFormatTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TimeFormatTests: XCTestCase {
    func testRawValueRoundTrip() {
        XCTAssertEqual(TimeFormat(rawValue: "twelveHour"), .twelveHour)
        XCTAssertEqual(TimeFormat(rawValue: "twentyFourHour"), .twentyFourHour)
    }

    func testAllCasesCount() {
        XCTAssertEqual(TimeFormat.allCases.count, 2)
    }
}
