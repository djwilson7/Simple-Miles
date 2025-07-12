import XCTest
@testable import Simple_Miles

final class EmailValidatorTests: XCTestCase {
    
    // MARK: - Valid Email Formats
    func testValidEmails() {
        XCTAssertTrue(EmailValidator.isValid("test@example.com"))
        XCTAssertTrue(EmailValidator.isValid("john.doe@domain.org"))
        XCTAssertTrue(EmailValidator.isValid("user123@sub.domain.net"))
        XCTAssertTrue(EmailValidator.isValid("first.last@domain.co"))
        XCTAssertTrue(EmailValidator.isValid("a_b-c.d@domain.com"))
    }

    // MARK: - Invalid: Missing Components
    func testMissingUsername() {
        XCTAssertFalse(EmailValidator.isValid("@example.com"))
    }
    
    func testMissingAtSymbol() {
        XCTAssertFalse(EmailValidator.isValid("testexample.com"))
    }
    
    func testMissingDomain() {
        XCTAssertFalse(EmailValidator.isValid("user@"))
    }
    
    func testMissingSuffix() {
        XCTAssertFalse(EmailValidator.isValid("user@domain"))
    }

    func testMissingDotBeforeSuffix() {
        XCTAssertFalse(EmailValidator.isValid("user@domaincom"))
    }

    func testOnlyDomainSuffix() {
        XCTAssertFalse(EmailValidator.isValid("@.com"))
    }

    // MARK: - Invalid: Malformed Patterns
    func testDoubleAtSymbols() {
        XCTAssertFalse(EmailValidator.isValid("user@@domain.com"))
    }

    func testTrailingDotInDomain() {
        XCTAssertFalse(EmailValidator.isValid("user@domain."))
    }

    func testLeadingDotInDomain() {
        XCTAssertFalse(EmailValidator.isValid("user@.domain.com"))
    }

    func testMultipleConsecutiveDots() {
        XCTAssertFalse(EmailValidator.isValid("test..test@domain.com"))
    }

    func testLeadingDotInUsername() {
        XCTAssertFalse(EmailValidator.isValid(".user@domain.com"))
    }

    func testTrailingDotInUsername() {
        XCTAssertFalse(EmailValidator.isValid("user.@domain.com"))
    }

    // MARK: - Invalid: Illegal Characters
    func testSpaceInEmail() {
        XCTAssertFalse(EmailValidator.isValid("te st@domain.com"))
    }

    func testSpecialCharactersInDomain() {
        XCTAssertFalse(EmailValidator.isValid("user@dom#ain.com"))
        XCTAssertFalse(EmailValidator.isValid("user@dom$ain.com"))
        XCTAssertFalse(EmailValidator.isValid("user@dom!ain.com"))
    }

    func testSpecialCharactersInUsername() {
        XCTAssertFalse(EmailValidator.isValid("us#er@domain.com"))
        XCTAssertFalse(EmailValidator.isValid("us$er@domain.com"))
        XCTAssertFalse(EmailValidator.isValid("us%er@domain.com"))
    }

    func testEmojiInEmail() {
        XCTAssertFalse(EmailValidator.isValid("🔥user@domain.com"))
        XCTAssertFalse(EmailValidator.isValid("user@domain💀.com"))
    }

    func testEmailWithNewlineCharacters() {
        XCTAssertFalse(EmailValidator.isValid("user\n@domain.com"))
        XCTAssertFalse(EmailValidator.isValid("user@domain.com\r"))
    }
    
    func testEmailWithTabs() {
        XCTAssertFalse(EmailValidator.isValid("user\t@domain.com"))
    }

    // MARK: - Invalid: Empty Input
    func testEmptyEmail() {
        XCTAssertFalse(EmailValidator.isValid(""))
    }

    func testWhitespaceOnlyEmail() {
        XCTAssertFalse(EmailValidator.isValid("     "))
    }
}
