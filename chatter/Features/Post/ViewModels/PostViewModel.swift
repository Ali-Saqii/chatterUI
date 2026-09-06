//
//  PostViewModel.swift
//  chatter
//

import SwiftUI
import Combine
import PhotosUI

@MainActor
final class PostViewModel: ObservableObject {
    // Post Creation State
    @Published var postText: String = ""
    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var selectedMediaData: Data? = nil
    @Published var selectedMediaType: MediaType = .none
    @Published var previewImage: UIImage? = nil
    @Published var isCreatingPost: Bool = false
    @Published var creationErrorMessage: String? = nil
    
    // Post Detail & Comments State
    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoadingComments: Bool = false
    @Published var isSubmittingComment: Bool = false
    @Published var commentErrorMessage: String? = nil
    
    // MARK: - Media Selection
    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                self.selectedMediaData = data
                
                // Determine if image or video
                if let uiImage = UIImage(data: data) {
                    self.previewImage = uiImage
                    self.selectedMediaType = .image
                } else {
                    // Video or other format
                    self.selectedMediaType = .video
                }
            }
        } catch {
            creationErrorMessage = "Failed to load selected media."
        }
    }
    
    func clearSelectedMedia() {
        self.selectedPhotoItem = nil
        self.selectedMediaData = nil
        self.selectedMediaType = .none
        self.previewImage = nil
    }
    
    // MARK: - Create Post
    func createPost() async -> Bool {
        let trimmedText = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation: must have text and/or media, never both empty
        guard !trimmedText.isEmpty || selectedMediaData != nil else {
            creationErrorMessage = "Post must have text or media."
            return false
        }
        
        isCreatingPost = true
        creationErrorMessage = nil
        defer { isCreatingPost = false }
        
        do {
            var fields: [String: String] = [:]
            if !trimmedText.isEmpty {
                fields["text"] = trimmedText
            }
            
            var files: [MultipartFile] = []
            if let mediaData = selectedMediaData {
                let isImg = selectedMediaType == .image
                let fileName = isImg ? "media.jpg" : "media.mp4"
                let mimeType = isImg ? "image/jpeg" : "video/mp4"
                
                files.append(
                    MultipartFile(
                        fieldName: "media",
                        fileName: fileName,
                        mimeType: mimeType,
                        data: mediaData
                    )
                )
            }
            
            let _: Post = try await APIClient.shared.uploadMultipart(
                .createPost,
                fields: fields,
                files: files
            )
            
            // Clear inputs on success
            postText = ""
            clearSelectedMedia()
            return true
        } catch {
            creationErrorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Comments (Placeholder / Ready for future wiring)
    func loadComments(for postId: String) async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        // Structured for one-line hookup when backend endpoint is ready:
        // do {
        //     self.comments = try await APIClient.shared.request(.getComments(postId: postId))
        // } catch { ... }
        
        // Fallback to initial mock comments
        try? await Task.sleep(nanoseconds: 300_000_000)
        self.comments = Comment.mockComments(for: postId)
    }
    
    func submitComment(for postId: String, currentUser: User?) async {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let user = currentUser else { return }
        
        isSubmittingComment = true
        defer { isSubmittingComment = false }
        
        // Structured for one-line backend activation:
        // do {
        //     let newComment: Comment = try await APIClient.shared.request(.addComment(postId: postId), body: ["text": trimmed])
        //     comments.append(newComment)
        // } catch { ... }
        
        let newComment = Comment(
            id: UUID().uuidString,
            post: postId,
            author: user,
            text: trimmed,
            createdAt: Date()
        )
        
        withAnimation(.easeOut(duration: 0.25)) {
            comments.append(newComment)
            newCommentText = ""
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
