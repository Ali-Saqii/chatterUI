//
//  RegisterView.swift
//  chatter
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.chatterLargeTitle)
                        .foregroundColor(.chatterText)
                    
                    Text("Join Chatter today and connect with people")
                        .font(.chatterSubheadline)
                        .foregroundColor(.chatterSubtext)
                }
                .padding(.top, 20)
                
                // Form Fields Card
                VStack(spacing: 16) {
                    // Full Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.text.rectangle")
                                .foregroundColor(.chatterPrimary)
                                .frame(width: 20)
                            
                            TextField("e.g. Jane Doe", text: $viewModel.registerFullName)
                                .font(.chatterBody)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "at")
                                .foregroundColor(.chatterPrimary)
                                .frame(width: 20)
                            
                            TextField("e.g. janedoe", text: $viewModel.registerUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.chatterBody)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.chatterPrimary)
                                .frame(width: 20)
                            
                            TextField("e.g. jane@example.com", text: $viewModel.registerEmail)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.chatterBody)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.chatterPrimary)
                                .frame(width: 20)
                            
                            if viewModel.showRegisterPassword {
                                TextField("Create a strong password", text: $viewModel.registerPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            } else {
                                SecureField("Create a strong password", text: $viewModel.registerPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            }
                            
                            Button(action: {
                                viewModel.showRegisterPassword.toggle()
                            }) {
                                Image(systemName: viewModel.showRegisterPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.chatterSubtext)
                                    .frame(width: 20)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Error Notice
                    if let error = viewModel.errorMessage {
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
                    
                    // Submit Button
                    PrimaryButton(
                        title: "Create Account",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.register(appState: appState)
                        }
                    }
                    .padding(.top, 8)
                }
                .chatterCard()
                .padding(.horizontal, 20)
                
                // Back to Login
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.chatterSubheadline)
                            .foregroundColor(.chatterSubtext)
                        Text("Log In")
                            .font(.chatterHeadline)
                            .foregroundColor(.chatterPrimary)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.clearErrors()
        }
    }
}
