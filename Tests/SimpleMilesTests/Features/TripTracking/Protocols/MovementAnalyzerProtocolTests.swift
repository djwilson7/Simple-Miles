//
//  MovementAnalyzerProtocolTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

// Tests/SimpleMilesTests/Features/TripTracking/Protocols/MovementAnalyzerProtocolTests.swift

import XCTest
@testable import SimpleMiles

/// Smoke‐test to ensure the struct actually conforms to the protocol.
final class MovementAnalyzerProtocolTests: XCTestCase {
    func testMovementAnalyzerConformsToProtocol() {
        // This will fail at compile time if MovementAnalyzer
        // does not implement all protocol requirements.
        let _: MovementAnalyzing = MovementAnalyzer()
        XCTAssertTrue(true)
    }
}

