//
//  ChatListViewModel.swift
//  chatter
//

import SwiftUI
import Combine

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showNewChatSheet: Bool = false
    
    // Friends list for starting new chat
    @Published var friends: [User] = []
    @Published var isLoadingFriends: Bool = false
    
    // All users in community for starting new chat
    @Published var allUsers: [User] = []
    @Published var isLoadingUsers: Bool = false
    
    // Search
    @Published var searchResults: [User] = []
    @Published var isSearching: Bool = false
    
    init() {
        let cached = CoreDataManager.shared.loadCachedConversations()
        if !cached.isEmpty {
            self.conversations = cached
        }
        let cachedFriends = CoreDataManager.shared.loadCachedFriends()
        if !cachedFriends.isEmpty {
            self.friends = cachedFriends
        }
    }
    
    func fetchConversations() async {
        if conversations.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            let data: ConversationListData = try await APIClient.shared.request(.getConversations(page: 1, limit: 50))
            self.conversations = data.conversations
            CoreDataManager.shared.saveConversations(data.conversations)
        } catch {
            print("❌ [ChatListViewModel] Failed to fetch conversations: \(error)")
            if conversations.isEmpty {
                let cached = CoreDataManager.shared.loadCachedConversations()
                if !cached.isEmpty {
                    self.conversations = cached
                }
            }
            if !NetworkMonitor.shared.isConnected {
                self.errorMessage = "Offline mode — showing cached conversations."
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func fetchFriends() async {
        isLoadingFriends = true
        do {
            let response: PaginatedFriendsResponse = try await APIClient.shared.request(.getFriends(page: 1, limit: 100))
            self.friends = response.friends
            CoreDataManager.shared.saveFriends(response.friends)
        } catch {
            print("❌ [ChatListViewModel] Failed to fetch friends: \(error)")
            if friends.isEmpty {
                self.friends = CoreDataManager.shared.loadCachedFriends()
            }
        }
        isLoadingFriends = false
    }
    
    func fetchAllUsers() async {
        isLoadingUsers = true
        do {
            let response: PaginatedUsersResponse = try await APIClient.shared.request(.getAllUsers(page: 1, limit: 100))
            self.allUsers = response.users
        } catch {
            print("❌ [ChatListViewModel] Failed to fetch all users: \(error)")
        }
        isLoadingUsers = false
    }
    
    func loadNewChatData() async {
        async let friendsTask: () = fetchFriends()
        async let usersTask: () = fetchAllUsers()
        _ = await (friendsTask, usersTask)
    }
    
    func searchUsers(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.searchResults = []
            self.isSearching = false
            return
        }
        
        self.isSearching = true
        do {
            let response: PaginatedUsersResponse = try await APIClient.shared.request(.searchPeople(query: trimmed, page: 1, limit: 50))
            self.searchResults = response.users
        } catch {
            // Local fallback filter
            let lower = trimmed.lowercased()
            var seen = Set<String>()
            let combined = (friends + allUsers).filter { user in
                guard !seen.contains(user.id) else { return false }
                seen.insert(user.id)
                return user.fullName.lowercased().contains(lower) || user.username.lowercased().contains(lower)
            }
            self.searchResults = combined
        }
        self.isSearching = false
    }
    
    func createDirectConversation(user: User) async -> Conversation? {
        isLoading = true
        errorMessage = nil
        let body = CreateConversationRequest(participantIds: [user.id], isGroup: false, groupName: nil)
        
        do {
            var conversation: Conversation = try await APIClient.shared.request(.createConversation, body: body)
            
            // Enrich other participant info if backend returned raw unpopulated IDs
            if let index = conversation.participants.firstIndex(where: { $0.id == user.id }) {
                var p = conversation.participants[index]
                if p.username == nil || p.username?.isEmpty == true {
                    p.username = user.username
                    p.avatarURL = user.avatarURL
                    p.email = user.email
                    conversation.participants[index] = p
                }
            } else {
                conversation.participants.append(
                    ConversationParticipant(id: user.id, username: user.username, email: user.email, avatarURL: user.avatarURL)
                )
            }
            
            // Refresh conversation list in background
            Task {
                await fetchConversations()
            }
            isLoading = false
            return conversation
        } catch {
            print("❌ [ChatListViewModel] Failed to create direct conversation: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func createDirectConversation(userId: String) async -> Conversation? {
        if let user = (allUsers + friends).first(where: { $0.id == userId }) {
            return await createDirectConversation(user: user)
        }
        let fallbackUser = User(id: userId, fullName: "", username: "")
        return await createDirectConversation(user: fallbackUser)
    }
    
    func createGroupConversation(participantIds: [String], groupName: String, selectedUsers: [User] = []) async -> Conversation? {
        isLoading = true
        errorMessage = nil
        let body = CreateConversationRequest(participantIds: participantIds, isGroup: true, groupName: groupName)
        
        do {
            var conversation: Conversation = try await APIClient.shared.request(.createConversation, body: body)
            
            // Enrich participant details
            for user in selectedUsers {
                if let index = conversation.participants.firstIndex(where: { $0.id == user.id }) {
                    var p = conversation.participants[index]
                    if p.username == nil || p.username?.isEmpty == true {
                        p.username = user.username
                        p.avatarURL = user.avatarURL
                        p.email = user.email
                        conversation.participants[index] = p
                    }
                } else {
                    conversation.participants.append(
                        ConversationParticipant(id: user.id, username: user.username, email: user.email, avatarURL: user.avatarURL)
                    )
                }
            }
            
            Task {
                await fetchConversations()
            }
            isLoading = false
            return conversation
        } catch {
            print("❌ [ChatListViewModel] Failed to create group conversation: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func leaveConversation(id: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.leaveConversation(conversationId: id))
            self.conversations.removeAll { $0.id == id }
        } catch {
            print("❌ [ChatListViewModel] Failed to leave conversation: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
}
