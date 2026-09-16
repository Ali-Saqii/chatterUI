//
//  CreatePostView.swift
//  chatter
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var viewModel = PostViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var onPostCreated: (() -> Void)? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Author Mini Header
                if let currentUser = appState.currentUser {
                    HStack(spacing: 12) {
                        AvatarView(urlString: currentUser.avatarURL, name: currentUser.fullName, size: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentUser.fullName)
                                .font(.chatterHeadline)
                                .foregroundColor(.chatterText)
                            Text("@\(currentUser.username)")
                                .font(.chatterCaption)
                                .foregroundColor(.chatterSubtext)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                
                // Text Editor
                ZStack(alignment: .topLeading) {
                    if viewModel.postText.isEmpty {
                        Text("What's on your mind?")
                            .font(.chatterBody)
                            .foregroundColor(.chatterSubtext.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $viewModel.postText)
                        .font(.chatterBody)
                        .frame(minHeight: 120)
                        .padding(.horizontal, 12)
                        .scrollContentBackground(.hidden)
                }
                .background(Color.chatterInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                
                // Media Preview if selected
                if let previewImage = viewModel.previewImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        Button(action: {
                            viewModel.clearSelectedMedia()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, 16)
                } else if viewModel.selectedMediaType == .video {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.chatterInputBackground)
                            .frame(height: 180)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.chatterPrimary)
                                    Text("Video Attached")
                                        .font(.chatterSubheadline)
                                        .foregroundColor(.chatterText)
                                }
                            )
                        
                        Button(action: {
                            viewModel.clearSelectedMedia()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Media Picker Action Row
                HStack {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .any(of: [.images, .videos])
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Photo or Video")
                                .font(.chatterSubheadline)
                        }
                        .foregroundColor(.chatterPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.chatterPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .onChange(of: viewModel.selectedPhotoItem) { newItem in
                        Task {
                            await viewModel.handlePhotoSelection(newItem)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // Error display
                if let error = viewModel.creationErrorMessage {
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
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("New Post")
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
                    title: "Post",
                    isLoading: viewModel.isCreatingPost,
                    isDisabled: viewModel.postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.selectedMediaData == nil,
                    height: 36
                ) {
                    Task {
                        let success = await viewModel.createPost()
                        if success {
                            appState.showBanner("Post published!", type: .success)
                            onPostCreated?()
                            dismiss()
                        }
                    }
                }
                .frame(width: 84)
            }
        }
    }
}
#Preview {
    CreatePostView (onPostCreated: {})
        .environmentObject(AppState())
}
