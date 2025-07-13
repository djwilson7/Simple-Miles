//
//  MockAuth.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

@testable import SimpleMiles
import XCTest

class MockAuthService: AuthProtocol {
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
