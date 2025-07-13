//
//  LoginView.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = AuthViewModel(authService: AuthService.shared)
    
    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.isLogin ? "Login" : "Sign Up")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $viewModel.email)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            
            //If we are logging in or signing up with email
            Button(viewModel.isLogin ? "Login with Email" : "Sign Up with Email") {
                viewModel.authenticateEmail()
            }
            
            //If user needs to create an account or would like to log in
            Button(viewModel.isLogin ? "Need an account? Sign Up" : "Have an account? Login") {
                viewModel.toggleMode()
            }
            .font(.footnote)
            .padding(.top, 10)
            
            if let message = viewModel.statusMessage {
                Text(message)
                    .foregroundColor(viewModel.isStatusError ? .red : .green)
                    .font(.caption)
                    .padding(.top, 10)
            }
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
