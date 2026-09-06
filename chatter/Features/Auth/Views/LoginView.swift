//
//  LoginView.swift
//  chatter
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Brand Header
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.chatterGradient)
                            .frame(width: 76, height: 76)
                            .shadow(color: Color.chatterPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    Text("Chatter")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.chatterGradient)
                    
                    Text("Connect, share, and chat with friends")
                        .font(.chatterSubheadline)
                        .foregroundColor(.chatterSubtext)
                }
                
                // Form Fields Card
                VStack(spacing: 18) {
                    // Identifier Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username or Email")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.chatterPrimary)
                                .frame(width: 20)
                            
                            TextField("Enter username or email", text: $viewModel.loginIdentifier)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.chatterBody)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.chatterPrimary)
                                .frame(width: 20)
                            
                            if viewModel.showLoginPassword {
                                TextField("Enter password", text: $viewModel.loginPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            } else {
                                SecureField("Enter password", text: $viewModel.loginPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.chatterBody)
                            }
                            
                            Button(action: {
                                viewModel.showLoginPassword.toggle()
                            }) {
                                Image(systemName: viewModel.showLoginPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.chatterSubtext)
                                    .frame(width: 20)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        NavigationLink(destination: ForgotPasswordView(viewModel: viewModel)) {
                            Text("Forgot Password?")
                                .font(.chatterCaptionBold)
                                .foregroundColor(.chatterPrimary)
                        }
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
                    
                    // Login Button
                    PrimaryButton(
                        title: "Log In",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.login(appState: appState)
                        }
                    }
                    .padding(.top, 6)
                }
                .chatterCard()
                .padding(.horizontal, 20)
                
                // Register Footer
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.chatterSubheadline)
                        .foregroundColor(.chatterSubtext)
                    
                    NavigationLink(destination: RegisterView(viewModel: viewModel)) {
                        Text("Sign Up")
                            .font(.chatterHeadline)
                            .foregroundColor(.chatterPrimary)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.clearErrors()
        }
    }
}
