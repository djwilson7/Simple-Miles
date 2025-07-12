//
//  PasswordValidationTests.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import XCTest
@testable import Simple_Miles

final class PasswordValidationTests: XCTestCase {
    
    func testEmptyPasswordFails() {
        let result = PasswordValidator.validate("   ")
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .onlyWhitespace)
        default:
            XCTFail("Expected failure for empty password")
        }
    }

    func testTooShortPasswordFails() {
        let result = PasswordValidator.validate("Tes1!")
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .tooShort)
        default:
            XCTFail("Expected failure for short password")
        }
    }

    func testMissingUppercaseFails() {
        let result = PasswordValidator.validate("testpassword1!")
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .missingUppercase)
        default:
            XCTFail("Expected failure for missing uppercase")
        }
    }

    func testMissingLowercaseFails() {
        let result = PasswordValidator.validate("TESTPASSWORD1!")
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .missingLowercase)
        default:
            XCTFail("Expected failure for missing lowercase")
        }
    }

    func testMissingDigitFails() {
        let result = PasswordValidator.validate("TestPassword!")
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .missingDigit)
        default:
            XCTFail("Expected failure for missing digit")
        }
    }

    func testMissingSpecialCharacterFails() {
        let result = PasswordValidator.validate("TestPassword1")
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .missingSpecialCharacter)
        default:
            XCTFail("Expected failure for missing special character")
        }
    }

    func testValidPasswordSucceeds() {
        let result = PasswordValidator.validate("TestPassword1!")
        switch result {
        case .success:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected success for valid password")
        }
    }
}
