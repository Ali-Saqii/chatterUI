//
//  PostDetailView.swift
//  chatter
//

import SwiftUI

struct PostDetailView: View {
    @State var post: Post
    var onPostUpdated: ((Post) -> Void)? = nil
    @StateObject private var viewModel = PostViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Main Post Card
                    PostRowView(
                        post: post,
                        allowsFullScreen: true,
                        onLikeTapped: {
                            post = PostActionService.toggleLike(on: post)
                            onPostUpdated?(post)
                        },
                        onDeleteTapped: nil,
                        onCommentTapped: nil
                    )
                    
                    // Comments Header
                    HStack {
                        Text("Comments (\(viewModel.comments.count))")
                            .font(.chatterHeadline)
                            .foregroundColor(.chatterText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Comments List
                    if viewModel.isLoadingComments {
                        ProgressView()
                            .padding(.vertical, 20)
                    } else if viewModel.comments.isEmpty {
                        VStack(spacing: 8) {
                            Text("No comments yet")
                                .font(.chatterSubheadline)
                                .foregroundColor(.chatterSubtext)
                            Text("Start the conversation below!")
                                .font(.chatterCaption)
                                .foregroundColor(.chatterTertiaryText)
                        }
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(viewModel.comments) { comment in
                                CommentRowView(comment: comment)
                                
                                if comment.id != viewModel.comments.last?.id {
                                    Divider()
                                        .padding(.leading, 48)
                                }
                            }
                        }
                        .chatterCard(padding: 14)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            
            // Pinned Bottom Comment Input Bar
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    if let current = appState.currentUser {
                        AvatarView(urlString: current.avatarURL, name: current.fullName, size: 34)
                    }
                    
                    TextField("Add a comment...", text: $viewModel.newCommentText)
                        .font(.chatterBody)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.chatterInputBackground)
                        .clipShape(Capsule())
                    
                    Button(action: {
                        Task {
                            await viewModel.submitComment(for: post.id, currentUser: appState.currentUser)
                            post.commentsCount = viewModel.comments.count
                            onPostUpdated?(post)
                        }
                    }) {
                        if viewModel.isSubmittingComment {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? AnyShapeStyle(Color.chatterSubtext.opacity(0.4))
                                        : AnyShapeStyle(Color.chatterGradient)
                                )
                        }
                    }
                    .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmittingComment)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.chatterCardBackground)
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments(for: post.id)
        }
    }
}

#Preview("Post Detail") {
    NavigationStack {
        PostDetailView(post: Post.mock)
            .environmentObject(AppState())
    }
}
