//
//  PostViewModel.swift
//  chatter
//

import SwiftUI
import PhotosUI
import Combine

private struct AddCommentRequestBody: Encodable {
    let content: String  // Backend expects 'content' field (not 'text')
}

/// Backend returns: { "data": { "post": { ... } } } — nested one level
private struct CreatePostWrapper: Decodable {
    let post: Post
}

@MainActor
final class PostViewModel: ObservableObject {
    // Post Creation State
    @Published var postText: String = ""
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedMediaData: Data?
    @Published var selectedMediaType: MediaType = .none
    @Published var previewImage: UIImage?
    @Published var videoURL: URL?          // local temp URL for video preview/playback
    @Published var isCreatingPost: Bool = false
    @Published var creationErrorMessage: String?
    
    // Post Detail & Comments State
    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoadingComments: Bool = false
    @Published var isSubmittingComment: Bool = false
    @Published var commentErrorMessage: String?
    
    // MARK: - Media Selection
    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                self.selectedMediaData = data
                
                // Try to decode as image first
                if let uiImage = UIImage(data: data) {
                    self.previewImage = uiImage
                    self.videoURL = nil
                    self.selectedMediaType = .image
                } else {
                    // It's a video — write data to a temp file for AVPlayer
                    self.previewImage = nil
                    self.selectedMediaType = .video
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mp4")
                    try data.write(to: tempURL)
                    self.videoURL = tempURL
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
        self.videoURL = nil
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
            
            // Backend wraps created post in data.post — use wrapper to decode correctly
            let _: CreatePostWrapper = try await APIClient.shared.uploadMultipart(
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
    
    // MARK: - Comments
    func loadComments(for postId: String) async {
        let cached = CoreDataManager.shared.loadCachedComments(for: postId)
        if !cached.isEmpty {
            self.comments = cached
        }
        
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        print("📥 [PostViewModel] loadComments — postId: \(postId)")
        do {
            let loadedComments: [Comment] = try await APIClient.shared.request(.getComments(postId: postId))
            print("✅ [PostViewModel] Comments loaded: \(loadedComments.count)")
            self.comments = loadedComments
            CoreDataManager.shared.saveComments(loadedComments, for: postId)
        } catch {
            print("❌ [PostViewModel] loadComments failed — \(error.localizedDescription)")
            if self.comments.isEmpty {
                self.comments = CoreDataManager.shared.loadCachedComments(for: postId)
            }
        }
    }
    
    func submitComment(for postId: String, currentUser: User?) async {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let user = currentUser else { return }
        
        isSubmittingComment = true
        defer { isSubmittingComment = false }
        
        let tempComment = Comment(
            id: UUID().uuidString,
            post: postId,
            author: user,
            text: trimmed,
            createdAt: Date()
        )
        
        withAnimation(.easeOut(duration: 0.25)) {
            comments.append(tempComment)
            newCommentText = ""
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        do {
            let body = AddCommentRequestBody(content: trimmed)
            let createdComment: Comment = try await APIClient.shared.request(
                .addComment(postId: postId),
                body: body
            )
            if let index = comments.firstIndex(where: { $0.id == tempComment.id }) {
                comments[index] = createdComment
            }
            CoreDataManager.shared.saveComments(self.comments, for: postId)
        } catch {
            // Keep the optimistic comment if endpoint not yet ready
            CoreDataManager.shared.saveComments(self.comments, for: postId)
        }
    }
}
