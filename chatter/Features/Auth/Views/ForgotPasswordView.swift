//
//  ForgotPasswordView.swift
//  chatter
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if viewModel.forgotPasswordSuccess {
                    // Success Confirmation State
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.chatterSuccess.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 38))
                                .foregroundColor(.chatterSuccess)
                        }
                        .padding(.top, 40)
                        
                        Text("Check Your Email")
                            .font(.chatterLargeTitle)
                            .foregroundColor(.chatterText)
                        
                        Text("We've sent a new password to **\(viewModel.forgotPasswordEmail)**. Check your inbox and spam folder, then log in using your new credentials.")
                            .font(.chatterBody)
                            .foregroundColor(.chatterSubtext)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        PrimaryButton(title: "Return to Login") {
                            viewModel.forgotPasswordSuccess = false
                            dismiss()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .chatterCard()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                } else {
                    // Input State
                    VStack(spacing: 8) {
                        Text("Reset Password")
                            .font(.chatterLargeTitle)
                            .foregroundColor(.chatterText)
                        
                        Text("Enter the email associated with your account and we'll send you a temporary password.")
                            .font(.chatterSubheadline)
                            .foregroundColor(.chatterSubtext)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 30)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.chatterCaptionBold)
                                .foregroundColor(.chatterSubtext)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.chatterPrimary)
                                    .frame(width: 20)
                                
                                TextField("Enter your registered email", text: $viewModel.forgotPasswordEmail)
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
                        
                        PrimaryButton(
                            title: "Send Reset Email",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.sendForgotPassword()
                            }
                        }
                    }
                    .chatterCard()
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.clearErrors()
        }
    }
}
