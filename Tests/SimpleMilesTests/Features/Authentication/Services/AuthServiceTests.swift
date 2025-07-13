//
//  AuthServiceTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

// Tests/SimpleMilesTests/Features/Authentication/Services/AuthServiceTests.swift

import XCTest
@testable import SimpleMiles

final class AuthServiceTests: XCTestCase {
  private var session: MockAuthSession!
  private var service: AuthService!

  override func setUp() {
    super.setUp()
    session = MockAuthSession()
    service = AuthService(session: session)   // inject the spy!
  }

  override func tearDown() {
    service = nil
    session = nil
    super.tearDown()
  }

  func testLoginForwardsParametersToSession() {
    session.result = .failure(NSError())  // drive the completion
    let exp = expectation(description: "")
    service.login("a@b.com","pw") { _ in exp.fulfill() }
    waitForExpectations(timeout: 1)
    XCTAssertEqual(session.loginArgs?.email, "a@b.com")
    XCTAssertEqual(session.loginArgs?.password, "pw")
  }

  func testSignupForwardsParametersToSession() {
    session.result = .failure(NSError())
    let exp = expectation(description: "")
    service.signup("x@y.com","123") { _ in exp.fulfill() }
    waitForExpectations(timeout: 1)
    XCTAssertEqual(session.signupArgs?.email, "x@y.com")
    XCTAssertEqual(session.signupArgs?.password, "123")
  }

  func testLoginPropagatesError() {
    let err = NSError(domain:"D", code:99, userInfo:nil)
    session.result = .failure(err)
    let exp = expectation(description: "")
    service.login("","") {
      if case .failure(let e as NSError) = $0 {
        XCTAssertEqual(e, err)
      } else { XCTFail() }
      exp.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testSignupPropagatesError() {
    let err = NSError(domain:"D2", code:100, userInfo:nil)
    session.result = .failure(err)
    let exp = expectation(description: "")
    service.signup("","") {
      if case .failure(let e as NSError) = $0 {
        XCTAssertEqual(e, err)
      } else { XCTFail() }
      exp.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testLoginSuccess() {
    let email = "ok@ok.com"
    session.result = .success(UserModel(email: email))
    let exp = expectation(description: "")
    service.login(email,"!") {
      if case .success(let m) = $0 {
        XCTAssertEqual(m.email, email)
      } else { XCTFail() }
      exp.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testSignupSuccess() {
    let email = "yo@yo.com"
    session.result = .success(UserModel(email: email))
    let exp = expectation(description: "")
    service.signup(email,"!") {
      if case .success(let m) = $0 {
        XCTAssertEqual(m.email, email)
      } else { XCTFail() }
      exp.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
