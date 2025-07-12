//
//  AuthService.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import Foundation
import FirebaseAuth

final class AuthService: AuthProviding {
    static let shared = AuthService()
    private init() {}
    typealias AnyUserType = UserModel
    
    func login(_ email: String, _ password: String, completion: @escaping (Result<UserModel, any Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                let userModel = UserModel(email: user.email)
                completion(.success(userModel))
            } else {
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."])))
            }
        }
    }
    
    func signup(_ email: String, _ password: String, completion: @escaping (Result<UserModel, any Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                let userModel = UserModel(email: user.email)
                completion(.success(userModel))
            } else {
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."])))
            }
        }
    }
    

}
