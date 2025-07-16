//
//  TripTypeTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
@testable import SimpleMiles

final class TripTypeTests: XCTestCase {

    /// Verifies that allCases contains exactly the expected cases in order.
    func testAllCases() {
        let expected: [TripType] = [.business, .personal, .unclassified]
        XCTAssertEqual(TripType.allCases, expected)
    }

    /// Verifies that each case’s rawValue matches its string representation.
    func testRawValues() {
        XCTAssertEqual(TripType.business.rawValue, "Business")
        XCTAssertEqual(TripType.personal.rawValue, "Personal")
        XCTAssertEqual(TripType.unclassified.rawValue, "Unclassified")
    }

    /// Verifies that each case can be encoded to JSON and decoded back correctly.
    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for original in TripType.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(TripType.self, from: data)
            XCTAssertEqual(decoded, original, "Round-trip encoding/decoding failed for \(original)")
        }
    }

    /// Verifies that decoding an invalid rawValue throws a decoding error.
    func testDecodingInvalidRawValueThrows() {
        let invalidJSON = """
        "invalid_case"
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(
            try JSONDecoder().decode(TripType.self, from: invalidJSON)
        ) { error in
            // We expect a DecodingError.dataCorrupted error
            if case DecodingError.dataCorrupted(let context) = error {
                XCTAssertTrue(context.debugDescription.contains("Cannot initialize TripType"))
            } else {
                XCTFail("Expected dataCorrupted DecodingError, got \(error)")
            }
        }
    }
}
