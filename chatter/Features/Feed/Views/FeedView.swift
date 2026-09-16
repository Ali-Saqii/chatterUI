//
//  FeedView.swift
//  chatter
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            Color.chatterBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.posts.isEmpty {
                // Skeleton loading state
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { _ in
                            PostSkeletonView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                // Empty State
                EmptyStateView(
                    icon: "bubble.left.and.exclamationmark.bubble.right",
                    title: "No Posts Yet",
                    description: "Be the first to share something with the world!",
                    buttonTitle: "Create Post"
                ) {
                    viewModel.showCreatePostSheet = true
                }
            } else {
                // Feed List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostRowView(
                                    post: post,
                                    onLikeTapped: {
                                        viewModel.toggleLike(for: post)
                                    },
                                    onDeleteTapped: {
                                        Task {
                                            await viewModel.deletePost(postId: post.id)
                                        }
                                    },
                                    onCommentTapped: nil
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentPost: post)
                                }
                            }
                        }
                        
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 16)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await viewModel.fetchFeed(isRefresh: true)
                }
            }
        }
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(Color.chatterGradient)
                        .font(.system(size: 20, weight: .bold))
                    Text("Chatter")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.chatterGradient)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.showCreatePostSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.chatterGradient)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreatePostSheet) {
            NavigationStack {
                CreatePostView {
                    Task {
                        await viewModel.fetchFeed(isRefresh: true)
                    }
                }
            }
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.fetchFeed()
            }
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(AppState())

}
