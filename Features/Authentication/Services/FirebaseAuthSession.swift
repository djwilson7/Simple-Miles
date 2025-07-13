//
//  FirebaseAuthSession.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation
import FirebaseAuth

struct FirebaseAuthSession: AuthSession {
    func login(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(UserModel(email: user.email)))
            } else {
                completion(.failure(
                    NSError(
                        domain: "Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."]
                    )
                ))
            }
        }
    }

    func signup(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(UserModel(email: user.email)))
            } else {
                completion(.failure(
                    NSError(
                        domain: "Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."]
                    )
                ))
            }
        }
    }
}
