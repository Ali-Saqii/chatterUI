//
//  PostActionService.swift
//  chatter
//

import SwiftUI

/// Shared service for common post actions (like toggle, delete) with optimistic UI updates.
/// Eliminates duplicated logic across FeedViewModel, ProfileViewModel, and PostDetailView.
enum PostActionService {
    
    /// Performs an optimistic like toggle on a post, firing the API call in the background.
    /// Returns the updated post with toggled like state and adjusted count.
    static func toggleLike(on post: Post) -> Post {
        var updated = post
        updated.isLikedByMe.toggle()
        updated.likesCount += updated.isLikedByMe ? 1 : -1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.request(.toggleLike(postId: post.id))
            } catch {
                // Optimistic update — silently handle API failure
                // A more robust implementation could publish a rollback event
            }
        }
        
        return updated
    }
}
