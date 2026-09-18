//
//  PostActionService.swift
//  chatter
//

import SwiftUI

/// Shared service for common post actions (like toggle, delete) with optimistic UI updates.
/// Eliminates duplicated logic across FeedViewModel, ProfileViewModel, and PostDetailView.
enum PostActionService {
    
    /// Performs an optimistic like toggle on a post, firing the correct API call in the background.
    /// Returns the updated post with toggled like state and adjusted count.
    static func toggleLike(on post: Post) -> Post {
        var updated = post
        updated.isLikedByMe.toggle()
        updated.likesCount += updated.isLikedByMe ? 1 : -1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let willLike = updated.isLikedByMe
        let postId = post.id
        
        Task {
            do {
                // Backend has separate like/unlike endpoints
                let endpoint: APIEndpoint = willLike ? .likePost(postId: postId) : .unlikePost(postId: postId)
                let _: EmptyResponse = try await APIClient.shared.request(endpoint)
                print("✅ [PostActionService] \(willLike ? "Like" : "Unlike") success — postId: \(postId)")
            } catch {
                print("❌ [PostActionService] Like toggle failed — \(error.localizedDescription)")
            }
        }
        
        return updated
    }
}
