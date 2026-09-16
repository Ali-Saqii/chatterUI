//
//  EditProfileView.swift
//  chatter
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar with change photo overlay
                VStack(spacing: 8) {
                    PhotosPicker(
                        selection: $viewModel.selectedAvatarItem,
                        matching: .images
                    ) {
                        ZStack(alignment: .bottomTrailing) {
                            if let preview = viewModel.avatarPreviewImage {
                                Image(uiImage: preview)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())
                            } else {
                                AvatarView(
                                    urlString: viewModel.user?.avatarURL,
                                    name: viewModel.user?.fullName ?? "User",
                                    size: 96
                                )
                            }
                            
                            // Edit Badge
                            ZStack {
                                Circle()
                                    .fill(Color.chatterPrimary)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 2, y: 2)
                        }
                    }
                    .onChange(of: viewModel.selectedAvatarItem) { _, newItem in
                        Task {
                            await viewModel.handleAvatarSelection(newItem)
                        }
                    }
                    
                    Text("Change Photo")
                        .font(.chatterCaptionBold)
                        .foregroundColor(.chatterPrimary)
                }
                .padding(.top, 16)
                
                // Fields
                VStack(spacing: 16) {
                    // Full Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        TextField("Full Name", text: $viewModel.editFullName)
                            .font(.chatterBody)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.chatterInputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        TextField("Username", text: $viewModel.editUsername)
                            .font(.chatterBody)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.chatterInputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Bio
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bio")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        ZStack(alignment: .topLeading) {
                            if viewModel.editBio.isEmpty {
                                Text("Write a short bio...")
                                    .font(.chatterBody)
                                    .foregroundColor(.chatterSubtext.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $viewModel.editBio)
                                .font(.chatterBody)
                                .frame(minHeight: 80)
                                .padding(.horizontal, 10)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .chatterCard()
                .padding(.horizontal, 16)
                
                // Error display
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.chatterDestructive)
                        Text(error)
                            .font(.chatterCaption)
                            .foregroundColor(.chatterDestructive)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.chatterDestructive.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.chatterSubtext)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                PrimaryButton(
                    title: "Save",
                    isLoading: viewModel.isSavingProfile,
                    height: 36
                ) {
                    Task {
                        let success = await viewModel.saveProfile(appState: appState)
                        if success {
                            dismiss()
                        }
                    }
                }
                .frame(width: 76)
            }
        }
    }
}
