//
//  ExportFormatTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class ExportFormatTests: XCTestCase {
    func testRawValueRoundTrip() {
        XCTAssertEqual(ExportFormat(rawValue: "csv"), .csv)
        XCTAssertEqual(ExportFormat(rawValue: "json"), .json)
    }

    func testAllCasesCount() {
        XCTAssertEqual(ExportFormat.allCases.count, 2)
    }
}
