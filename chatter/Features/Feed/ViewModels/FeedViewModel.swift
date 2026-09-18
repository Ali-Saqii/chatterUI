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
    @Published var errorMessage: String?
    @Published var showCreatePostSheet: Bool = false
    
    private var currentPage = 1
    private let limit = 20
    private var canLoadMore = true
    
    func fetchFeed(isRefresh: Bool = false) async {
        print("🔄 [FeedViewModel] fetchFeed() called — isRefresh: \(isRefresh), currentPage: \(currentPage)")
        
        if isRefresh {
            isRefreshing = true
            currentPage = 1
            canLoadMore = true
            print("🔄 [FeedViewModel] Refresh mode — page reset to 1")
        } else {
            if posts.isEmpty {
                isLoading = true
                print("⏳ [FeedViewModel] Posts array khaali hai, loading state ON")
            }
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
            print("✅ [FeedViewModel] fetchFeed() complete — total posts: \(self.posts.count)")
        }
        
        do {
            print("📡 [FeedViewModel] API call kar raha hoon: .getFeed(page: \(currentPage), limit: \(limit))")
            let response: PaginatedPostsResponse = try await APIClient.shared.request(
                .getFeed(page: currentPage, limit: limit)
            )
            
            print("📦 [FeedViewModel] Response mila — posts count: \(response.posts.count)")
            print("📄 [FeedViewModel] Pagination: page=\(response.pagination.page), totalPages=\(response.pagination.totalPages), totalPosts=\(response.pagination.total)")
            
            if response.posts.isEmpty {
                print("⚠️ [FeedViewModel] Server ne 0 posts return kiye! Feed khaali hai ya koi post nahi.")
            } else {
                for (i, post) in response.posts.prefix(5).enumerated() {
                    print("   Post[\(i)]: id=\(post.id)")
                }
            }
            
            if isRefresh || currentPage == 1 {
                self.posts = response.posts
                print("🔁 [FeedViewModel] Posts replace (refresh/page 1) — naye posts: \(self.posts.count)")
            } else {
                let existingIds = Set(self.posts.map { $0.id })
                let newPosts = response.posts.filter { !existingIds.contains($0.id) }
                self.posts.append(contentsOf: newPosts)
                print("➕ [FeedViewModel] Posts append — naye \(newPosts.count) posts, total: \(self.posts.count)")
            }
            
            self.canLoadMore = response.pagination.page < response.pagination.totalPages
            if canLoadMore {
                currentPage += 1
                print("➡️ [FeedViewModel] Next page ready: \(currentPage)")
            } else {
                print("🏁 [FeedViewModel] Sab posts load ho gaye, aur pages nahi")
            }
        } catch {
            print("❌ [FeedViewModel] fetchFeed ERROR: \(error)")
            print("❌ [FeedViewModel] Error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreIfNeeded(currentPost: Post) async {
        guard canLoadMore, !isLoading, !isLoadingMore else {
            print("⏭️ [FeedViewModel] loadMoreIfNeeded skip — canLoadMore:\(canLoadMore), isLoading:\(isLoading), isLoadingMore:\(isLoadingMore)")
            return
        }
        
        guard let index = posts.firstIndex(where: { $0.id == currentPost.id }),
              index >= posts.count - 3 else {
            return
        }
        
        print("📡 [FeedViewModel] Load more — page \(currentPage) fetch kar raha hoon")
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let response: PaginatedPostsResponse = try await APIClient.shared.request(
                .getFeed(page: currentPage, limit: limit)
            )
            
            let existingIds = Set(self.posts.map { $0.id })
            let newPosts = response.posts.filter { !existingIds.contains($0.id) }
            self.posts.append(contentsOf: newPosts)
            print("➕ [FeedViewModel] Load more: \(newPosts.count) naye posts, total: \(self.posts.count)")
            
            self.canLoadMore = response.pagination.page < response.pagination.totalPages
            if canLoadMore {
                currentPage += 1
            }
        } catch {
            print("❌ [FeedViewModel] loadMore ERROR: \(error.localizedDescription)")
        }
    }
    
    func deletePost(postId: String) async {
        print("🗑️ [FeedViewModel] deletePost() — postId: \(postId)")
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deletePost(postId: postId))
            withAnimation {
                posts.removeAll { $0.id == postId }
            }
            print("✅ [FeedViewModel] Post delete ho gaya — remaining: \(posts.count)")
        } catch {
            print("❌ [FeedViewModel] deletePost ERROR: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleLike(for post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = PostActionService.toggleLike(on: posts[index])
    }
    
    func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
        }
    }
}
