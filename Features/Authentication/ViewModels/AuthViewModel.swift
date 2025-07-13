//
//  AuthViewModel.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import Foundation
import FirebaseAuth

class AuthViewModel<Service: AuthProtocol>: ObservableObject {
    private let authService: Service

    init(authService: Service) {
        self.authService = authService
    }
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLogin = true
    @Published var statusMessage: String?
    @Published var isStatusError: Bool = false
    
    func toggleMode() {
        isLogin.toggle()
        statusMessage = nil
        email = ""
        password = ""
    }
    
    func loginWithEmail(_ email: String, _ password: String) {
        authService.login(email, password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.handleAuthSuccess(message: "Logged In")
                case .failure(let error):
                    self.handleAuthFailure(message: "Login Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func signupWithEmail(_ email: String, _ password: String) {
        authService.signup(email, password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.handleAuthSuccess(message: "Account Created and Logged In")
                case .failure(let error):
                    self.handleAuthFailure(message: "Sign Up Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleAuthFailure(message: String) {
        DispatchQueue.main.async {
            self.statusMessage = "Error: \(message)"
            self.isStatusError = true
        }
    }
    
    private func handleAuthSuccess(message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
            self.isStatusError = false
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
    }
    
    func authenticateEmail() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
        guard !trimmedEmail.isEmpty else {
            statusMessage = "Email cannot be empty."
            isStatusError = true
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            statusMessage = "Password cannot be empty."
            isStatusError = true
            return
        }
        
        guard EmailValidator.isValid(trimmedEmail) else {
            statusMessage = "Invalid Email Entered"
            isStatusError = true
            return
        }
        
        if isLogin { //user is logging in
            loginWithEmail(trimmedEmail, trimmedPassword)
        } else {    //user is signing up
            switch PasswordValidator.validate(trimmedPassword) { //validate entered password
            case .success:  //if password is valid, sign up
                signupWithEmail(trimmedEmail, trimmedPassword)
            case .failure(let error): //else present error to user
                statusMessage = error.description
                isStatusError = true
            }
        }
    }
}
