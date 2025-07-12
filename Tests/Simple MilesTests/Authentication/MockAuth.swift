//
//  MockAuth.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

@testable import Simple_Miles
import XCTest

class MockAuthService: AuthProviding {
    typealias AuthUser = MockUserModel
    
    var shouldSucceed = true
    var mockEmail = "mock@user.com"
    
    func login(_ email: String, _ password: String, completion: @escaping (Result<MockUserModel, Error>) -> Void) {
        if shouldSucceed {
            completion(.success(MockUserModel(email: mockEmail)))
        } else {
            completion(.failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid login"])))
        }
    }

    func signup(_ email: String, _ password: String, completion: @escaping (Result<MockUserModel, Error>) -> Void) {
        if shouldSucceed {
            completion(.success(MockUserModel(email: mockEmail)))
        } else {
            completion(.failure(NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Signup failed"])))
        }
    }
}
