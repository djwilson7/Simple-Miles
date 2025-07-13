//
//  AuthSession.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation

/// A domain‐level abstraction over authentication.
/// All callbacks return *your* UserModel, never `AuthDataResult` or `User`.
protocol AuthSession {
    func login(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    )
    func signup(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    )
}

