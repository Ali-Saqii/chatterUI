//
//  ChangePasswordView.swift
//  chatter
//

import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var showOldPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Change Password")
                        .font(.chatterLargeTitle)
                        .foregroundColor(.chatterText)
                    
                    Text("Choose a strong, unique password to secure your account.")
                        .font(.chatterSubheadline)
                        .foregroundColor(.chatterSubtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 16)
                
                VStack(spacing: 16) {
                    // Old Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Password")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 10) {
                            if showOldPassword {
                                TextField("Current Password", text: $viewModel.oldPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            } else {
                                SecureField("Current Password", text: $viewModel.oldPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            }
                            
                            Button(action: { showOldPassword.toggle() }) {
                                Image(systemName: showOldPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.chatterSubtext)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Password (min. 6 characters)")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 10) {
                            if showNewPassword {
                                TextField("New Password", text: $viewModel.newPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            } else {
                                SecureField("New Password", text: $viewModel.newPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            }
                            
                            Button(action: { showNewPassword.toggle() }) {
                                Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.chatterSubtext)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Confirm New Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm New Password")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 10) {
                            if showConfirmPassword {
                                TextField("Confirm New Password", text: $viewModel.confirmNewPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            } else {
                                SecureField("Confirm New Password", text: $viewModel.confirmNewPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.chatterSubtext)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    if let error = viewModel.passwordErrorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.chatterDestructive)
                            Text(error)
                                .font(.chatterCaption)
                                .foregroundColor(.chatterDestructive)
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.chatterDestructive.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    PrimaryButton(
                        title: "Update Password",
                        isLoading: viewModel.isUpdatingPassword
                    ) {
                        Task {
                            let success = await viewModel.updatePassword(appState: appState)
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .chatterCard()
                .padding(.horizontal, 16)
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Change Password") {
    NavigationStack {
        ChangePasswordView(viewModel: SettingsViewModel())
            .environmentObject(AppState())
    }
}


