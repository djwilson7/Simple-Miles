//
//  AuthProviding.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import Foundation

/// Public-facing authentication contract for app consumers.
protocol AuthProtocol {
    /// The user type returned on successful authentication.
    associatedtype AnyUserType

    /// Attempts to authenticate the user; returns a domain model or an error.
    func login(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<AnyUserType, Error>) -> Void
    )

    /// Attempts to create a new account; returns a domain model or an error.
    func signup(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<AnyUserType, Error>) -> Void
    )
}
