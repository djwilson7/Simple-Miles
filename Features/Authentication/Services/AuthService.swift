//
//  AuthService.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//



import Foundation

final class AuthService: AuthProtocol {
    typealias AnyUserType = UserModel
    static let shared = AuthService()
    
    private let session: AuthSession

    /// Default to the Firebase-backed session, but allows injection of a mock for tests.
    init(session: AuthSession = FirebaseAuthSession()) {
        self.session = session
    }

    func login(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        session.login(email, password, completion: completion)
    }

    func signup(
        _ email: String,
        _ password: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        session.signup(email, password, completion: completion)
    }
}
