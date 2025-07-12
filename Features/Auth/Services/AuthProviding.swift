//
//  AuthProviding.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import Foundation
import FirebaseAuth

protocol AuthProviding {
    associatedtype AnyUserType
    func login(_ email: String, _ password: String, completion: @escaping (Result<AnyUserType, Error>) -> Void)
    func signup(_ email: String, _ password: String, completion: @escaping (Result<AnyUserType, Error>) -> Void)
}
