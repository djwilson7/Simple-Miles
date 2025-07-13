//
//  UserModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//
import XCTest
@testable import SimpleMiles

final class UserModelTests: XCTestCase {

    /// Verifies that UserModel stores a non‐nil email correctly.
    func testInitializationWithEmail() {
        let email = "test@example.com"
        let user = UserModel(email: email)
        XCTAssertEqual(user.email, email)
    }

    /// Verifies that UserModel handles a nil email.
    func testInitializationWithNilEmail() {
        let user = UserModel(email: nil)
        XCTAssertNil(user.email)
    }
}

