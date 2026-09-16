//
//  ProfileViewModel.swift
//  chatter
//

import SwiftUI
import Combine
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoadingProfile: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var friendActionState: FriendActionState = .loading
    @Published var errorMessage: String? = nil
    
    // Edit Profile State
    @Published var editFullName: String = ""
    @Published var editUsername: String = ""
    @Published var editBio: String = ""
    @Published var selectedAvatarItem: PhotosPickerItem? = nil
    @Published var selectedAvatarData: Data? = nil
    @Published var avatarPreviewImage: UIImage? = nil
    @Published var isSavingProfile: Bool = false
    @Published var showEditProfileSheet: Bool = false
    
    private let targetUsername: String?
    
    init(targetUsername: String? = nil) {
        self.targetUsername = targetUsername
    }
    
    func loadProfile(currentUser: User?) async {
        isLoadingProfile = true
        errorMessage = nil
        defer { isLoadingProfile = false }
        
        do {
            let loadedUser: User
            if let username = targetUsername, !username.isEmpty, username != currentUser?.username {
                loadedUser = try await APIClient.shared.request(.getUserProfile(username: username))
            } else {
                loadedUser = try await APIClient.shared.request(.getMyProfile)
            }
            self.user = loadedUser
            self.setupEditFields(from: loadedUser)
            
            // Determine relationship state
            await evaluateRelationshipState(targetUser: loadedUser, currentUser: currentUser)
            
            // Load user's posts
            await loadUserPosts(for: loadedUser, isSelf: loadedUser.id == currentUser?.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func setupEditFields(from user: User) {
        self.editFullName = user.fullName
        self.editUsername = user.username
        self.editBio = user.bio ?? ""
    }
    
    func loadUserPosts(for user: User, isSelf: Bool) async {
        isLoadingPosts = true
        defer { isLoadingPosts = false }
        
        do {
            let endpoint: APIEndpoint = isSelf ? .getMyPosts(page: 1, limit: 50) : .getUserPosts(userId: user.id, page: 1, limit: 50)
            let response: PaginatedPostsResponse = try await APIClient.shared.request(endpoint)
            self.posts = response.posts
        } catch {
            // Silently fallback if posts endpoint fails
        }
    }
    
    private func evaluateRelationshipState(targetUser: User, currentUser: User?) async {
        guard let current = currentUser else {
            friendActionState = .addFriend
            return
        }
        
        if targetUser.id == current.id || targetUser.username == current.username {
            friendActionState = .editProfile
            return
        }
        
        // Fetch friends and requests to determine exact relation
        do {
            async let friendsReq: PaginatedFriendsResponse = APIClient.shared.request(.getFriends(page: 1, limit: 100))
            async let sentReq: PaginatedRequestsResponse = APIClient.shared.request(.getSentRequests(page: 1, limit: 100))
            async let receivedReq: PaginatedRequestsResponse = APIClient.shared.request(.getReceivedRequests(page: 1, limit: 100))
            
            let (friends, sent, received) = try await (friendsReq, sentReq, receivedReq)
            
            // 1. Are they accepted friends?
            if let friendMatch = friends.friends.first(where: { $0.id == targetUser.id || $0.username == targetUser.username }) {
                friendActionState = .friends(friendId: friendMatch.id)
                return
            }
            
            // 2. Sent request pending?
            if let sentMatch = sent.requests.first(where: { $0.receiver.id == targetUser.id || $0.receiver.username == targetUser.username }) {
                friendActionState = .requestSent(requestId: sentMatch.id)
                return
            }
            
            // 3. Received request pending?
            if let recMatch = received.requests.first(where: { $0.sender.id == targetUser.id || $0.sender.username == targetUser.username }) {
                friendActionState = .requestReceived(requestId: recMatch.id)
                return
            }
            
            // 4. No relationship
            friendActionState = .addFriend
        } catch {
            // Default to add friend if relationship check fails
            friendActionState = .addFriend
        }
    }
    
    // MARK: - Friend Actions
    func sendFriendRequest(targetUserId: String) async {
        friendActionState = .loading
        do {
            let req: FriendRequest = try await APIClient.shared.request(.sendFriendRequest(userId: targetUserId))
            friendActionState = .requestSent(requestId: req.id)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
            friendActionState = .addFriend
        }
    }
    
    func acceptFriendRequest(requestId: String) async {
        friendActionState = .loading
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.acceptFriendRequest(requestId: requestId))
            friendActionState = .friends(friendId: user?.id)
            if var u = user {
                u.friendsCount += 1
                self.user = u
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func declineFriendRequest(requestId: String) async {
        friendActionState = .loading
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.declineFriendRequest(requestId: requestId))
            friendActionState = .addFriend
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelFriendRequest(requestId: String) async {
        friendActionState = .loading
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.cancelFriendRequest(requestId: requestId))
            friendActionState = .addFriend
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeFriend(friendId: String) async {
        friendActionState = .loading
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.removeFriend(friendId: friendId))
            friendActionState = .addFriend
            if var u = user, u.friendsCount > 0 {
                u.friendsCount -= 1
                self.user = u
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Edit Profile Actions
    func handleAvatarSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.selectedAvatarData = data
                self.avatarPreviewImage = image
            }
        } catch {
            errorMessage = "Failed to load image."
        }
    }
    
    func saveProfile(appState: AppState) async -> Bool {
        isSavingProfile = true
        errorMessage = nil
        defer { isSavingProfile = false }
        
        do {
            // 1. Partial user update
            var updateFields: [String: String] = [:]
            let trimmedName = editFullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUser = editUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedBio = editBio.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedName.isEmpty && trimmedName != user?.fullName {
                updateFields["fullName"] = trimmedName
            }
            if !trimmedUser.isEmpty && trimmedUser != user?.username {
                updateFields["username"] = trimmedUser
            }
            if trimmedBio != (user?.bio ?? "") {
                updateFields["bio"] = trimmedBio
            }
            
            var updatedUser: User = user ?? User(id: "", fullName: "", username: "")
            
            if !updateFields.isEmpty {
                updatedUser = try await APIClient.shared.request(.updateProfile, body: updateFields)
            }
            
            // 2. Avatar upload if new avatar selected
            if let avatarData = selectedAvatarData {
                let file = MultipartFile(
                    fieldName: "avatar",
                    fileName: "avatar.jpg",
                    mimeType: "image/jpeg",
                    data: avatarData
                )
                let avatarUser: User = try await APIClient.shared.uploadMultipart(
                    .updateProfilePicture,
                    files: [file]
                )
                updatedUser = avatarUser
            }
            
            self.user = updatedUser
            appState.updateCurrentUser(updatedUser)
            appState.showBanner("Profile updated successfully!", type: .success)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Post Actions
    func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
        }
    }
    
    func toggleLike(for post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        var updated = posts[index]
        updated.isLikedByMe.toggle()
        updated.likesCount += updated.isLikedByMe ? 1 : -1
        posts[index] = updated
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.request(.toggleLike(postId: post.id))
            } catch {}
        }
    }
    
    func deletePost(postId: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deletePost(postId: postId))
            withAnimation {
                posts.removeAll { $0.id == postId }
                if var u = user, u.postsCount > 0 {
                    u.postsCount -= 1
                    self.user = u
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
