//
//  SettingsViewModel.swift
//  chatter
//

import SwiftUI

struct UpdatePasswordRequestBody: Encodable {
    let oldPassword: String
    let newPassword: String
}

@MainActor
final class SettingsViewModel: ObservableObject {
    // Password Change State
    @Published var oldPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""
    @Published var isUpdatingPassword: Bool = false
    @Published var passwordErrorMessage: String? = nil
    
    // Account Deletion State
    @Published var isDeletingAccount: Bool = false
    @Published var deleteErrorMessage: String? = nil
    
    // MARK: - Update Password
    func updatePassword(appState: AppState) async -> Bool {
        let trimmedOld = oldPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmNewPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedOld.isEmpty else {
            passwordErrorMessage = "Current password is required."
            return false
        }
        guard trimmedNew.count >= 6 else {
            passwordErrorMessage = "New password must be at least 6 characters."
            return false
        }
        guard trimmedNew == trimmedConfirm else {
            passwordErrorMessage = "New passwords do not match."
            return false
        }
        
        isUpdatingPassword = true
        passwordErrorMessage = nil
        defer { isUpdatingPassword = false }
        
        do {
            let body = UpdatePasswordRequestBody(oldPassword: trimmedOld, newPassword: trimmedNew)
            let _: EmptyResponse = try await APIClient.shared.request(.updatePassword, body: body)
            
            oldPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            appState.showBanner("Password changed successfully.", type: .success)
            return true
        } catch {
            passwordErrorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount(appState: AppState) async -> Bool {
        isDeletingAccount = true
        deleteErrorMessage = nil
        defer { isDeletingAccount = false }
        
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deleteAccount)
            appState.logout()
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            return false
        }
    }
}
