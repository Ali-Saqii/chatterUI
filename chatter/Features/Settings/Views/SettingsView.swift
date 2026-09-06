//
//  SettingsView.swift
//  chatter
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showLogoutAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // User Profile Summary Card
                if let user = appState.currentUser {
                    HStack(spacing: 14) {
                        AvatarView(urlString: user.avatarURL, name: user.fullName, size: 56)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.chatterHeadline)
                                .foregroundColor(.chatterText)
                            
                            Text("@\(user.username)")
                                .font(.chatterSubheadline)
                                .foregroundColor(.chatterSubtext)
                            
                            if let email = user.email {
                                Text(email)
                                    .font(.chatterCaption)
                                    .foregroundColor(.chatterTertiaryText)
                            }
                        }
                        
                        Spacer()
                    }
                    .chatterCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                
                // Account Settings Section
                VStack(spacing: 0) {
                    NavigationLink(destination: ChangePasswordView(viewModel: viewModel)) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.chatterPrimary.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "lock.rotation")
                                    .foregroundColor(.chatterPrimary)
                                    .font(.system(size: 16))
                            }
                            
                            Text("Change Password")
                                .font(.chatterBody)
                                .foregroundColor(.chatterText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.chatterSubtext)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                    }
                    
                    Divider()
                        .padding(.leading, 62)
                    
                    NavigationLink(destination: DeleteAccountView(viewModel: viewModel)) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.chatterDestructive.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.chatterDestructive)
                                    .font(.system(size: 16))
                            }
                            
                            Text("Delete Account")
                                .font(.chatterBody)
                                .foregroundColor(.chatterDestructive)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.chatterSubtext)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                    }
                }
                .background(Color.chatterCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                
                // App Information Section
                VStack(spacing: 0) {
                    HStack {
                        Text("App Version")
                            .font(.chatterBody)
                            .foregroundColor(.chatterText)
                        Spacer()
                        Text("1.0.0 (Chatter iOS)")
                            .font(.chatterSubheadline)
                            .foregroundColor(.chatterSubtext)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    HStack {
                        Text("Backend API")
                            .font(.chatterBody)
                            .foregroundColor(.chatterText)
                        Spacer()
                        Text("Node.js / Express")
                            .font(.chatterSubheadline)
                            .foregroundColor(.chatterSubtext)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
                .background(Color.chatterCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                
                // Logout Button
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Log Out")
                            .font(.chatterHeadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.chatterDestructive)
                    .background(Color.chatterDestructive.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("Are you sure you want to log out of Chatter?")
        }
    }
}
