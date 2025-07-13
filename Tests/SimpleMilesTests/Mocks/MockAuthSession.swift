//
//  MockAuthSession.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//
import Foundation
@testable import SimpleMiles

final class MockAuthSession: AuthSession {
  // test‐spy storage
  private(set) var loginArgs: (email: String, password: String)?
  private(set) var signupArgs: (email: String, password: String)?

  // what the mock will return to the service
  var result: Result<UserModel, Error> = .failure(NSError(domain:"", code:0))

  func login(
    _ email: String,
    _ password: String,
    completion: @escaping (Result<UserModel, Error>) -> Void
  ) {
    loginArgs = (email, password)
    completion(result)
  }

  func signup(
    _ email: String,
    _ password: String,
    completion: @escaping (Result<UserModel, Error>) -> Void
  ) {
    signupArgs = (email, password)
    completion(result)
  }
}
