//
//  FeedViewModel.swift
//  chatter
//

import SwiftUI
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showCreatePostSheet: Bool = false
    
    private var currentPage = 1
    private let limit = 20
    private var canLoadMore = true
    
    func fetchFeed(isRefresh: Bool = false) async {
        if isRefresh {
            isRefreshing = true
            currentPage = 1
            canLoadMore = true
        } else {
            if posts.isEmpty {
                isLoading = true
            }
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
        }
        
        do {
            let response: PaginatedPostsResponse = try await APIClient.shared.request(
                .getFeed(page: currentPage, limit: limit)
            )
            
            if isRefresh || currentPage == 1 {
                self.posts = response.posts
            } else {
                // Deduplicate and append
                let existingIds = Set(self.posts.map { $0.id })
                let newPosts = response.posts.filter { !existingIds.contains($0.id) }
                self.posts.append(contentsOf: newPosts)
            }
            
            self.canLoadMore = response.pagination.page < response.pagination.totalPages
            if canLoadMore {
                currentPage += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreIfNeeded(currentPost: Post) async {
        guard canLoadMore, !isLoading, !isLoadingMore else { return }
        
        // Trigger when within last 3 items
        guard let index = posts.firstIndex(where: { $0.id == currentPost.id }),
              index >= posts.count - 3 else {
            return
        }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let response: PaginatedPostsResponse = try await APIClient.shared.request(
                .getFeed(page: currentPage, limit: limit)
            )
            
            let existingIds = Set(self.posts.map { $0.id })
            let newPosts = response.posts.filter { !existingIds.contains($0.id) }
            self.posts.append(contentsOf: newPosts)
            
            self.canLoadMore = response.pagination.page < response.pagination.totalPages
            if canLoadMore {
                currentPage += 1
            }
        } catch {
            // Silently handle pagination error
        }
    }
    
    func deletePost(postId: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deletePost(postId: postId))
            withAnimation {
                posts.removeAll { $0.id == postId }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleLike(for post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // Optimistic toggle
        var updated = posts[index]
        updated.isLikedByMe.toggle()
        updated.likesCount += updated.isLikedByMe ? 1 : -1
        posts[index] = updated
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Ready for 1-line real endpoint switch:
        Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.request(.toggleLike(postId: post.id))
            } catch {
                // If endpoint not implemented yet, placeholder mock keeps optimistic toggle
            }
        }
    }
}
