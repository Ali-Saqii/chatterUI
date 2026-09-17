//
//  AuthViewModel.swift
//  chatter
//

import SwiftUI
import Combine

struct LoginRequestBody: Encodable {
    let identifier: String
    let password: String
}

struct RegisterRequestBody: Encodable {
    let fullName: String
    let username: String
    let email: String
    let password: String
}

struct ForgotPasswordRequestBody: Encodable {
    let email: String
}

@MainActor
final class AuthViewModel: ObservableObject {
    // Login
    @Published var loginIdentifier: String = ""
    @Published var loginPassword: String = ""
    @Published var showLoginPassword: Bool = false
    
    // Register
    @Published var registerFullName: String = ""
    @Published var registerUsername: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPassword: String = ""
    @Published var showRegisterPassword: Bool = false
    
    // Forgot Password
    @Published var forgotPasswordEmail: String = ""
    @Published var forgotPasswordSuccess: Bool = false
    
    // Shared State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Actions
    func login(appState: AppState) async {
        let identifier = loginIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = loginPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !identifier.isEmpty else {
            errorMessage = "Please enter your username or email."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let body = LoginRequestBody(identifier: identifier, password: password)
            let response: AuthResponseData = try await APIClient.shared.request(.login, body: body)
            
            if let token = response.token {
                appState.setAuthenticated(token: token, user: response.user)
            } else {
                errorMessage = "Authentication succeeded but no token was provided."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func register(appState: AppState) async {
        let fullName = registerFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = registerUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = registerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = registerPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !fullName.isEmpty else {
            errorMessage = "Full name is required."
            return
        }
        guard !username.isEmpty else {
            errorMessage = "Username is required."
            return
        }
        guard !email.isEmpty else {
            errorMessage = "Email is required."
            return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let body = RegisterRequestBody(
                fullName: fullName,
                username: username,
                email: email,
                password: password
            )
            let response: AuthResponseData = try await APIClient.shared.request(.register, body: body)
            
            if let token = response.token {
                appState.setAuthenticated(token: token, user: response.user)
            } else {
                errorMessage = "Registration succeeded but no token was provided."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func sendForgotPassword() async {
        let email = forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let body = ForgotPasswordRequestBody(email: email)
            let _: EmptyResponse = try await APIClient.shared.request(.forgotPassword, body: body)
            forgotPasswordSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearErrors() {
        errorMessage = nil
    }
}
