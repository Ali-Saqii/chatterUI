//
//  PeopleViewModel.swift
//  chatter
//

import SwiftUI

@MainActor
final class PeopleViewModel: ObservableObject {
    @Published var selectedTab: Int = 0 // 0: All People, 1: Friends, 2: Requests
    
    // All People / Search
    @Published var searchQuery: String = ""
    @Published var allUsers: [User] = []
    @Published var isLoadingUsers: Bool = false
    
    // Friends
    @Published var friends: [User] = []
    @Published var isLoadingFriends: Bool = false
    
    // Requests
    @Published var receivedRequests: [FriendRequest] = []
    @Published var sentRequests: [FriendRequest] = []
    @Published var isLoadingRequests: Bool = false
    
    // State cache of requested user IDs for quick UI updates
    @Published var sentRequestUserIds: Set<String> = []
    @Published var friendUserIds: Set<String> = []
    
    @Published var errorMessage: String?
    
    // MARK: - All Users / Search
    func searchUsers() async {
        isLoadingUsers = true
        errorMessage = nil
        defer { isLoadingUsers = false }
        
        do {
            let response: PaginatedUsersResponse = try await APIClient.shared.request(
                .searchUsers(query: searchQuery, page: 1, limit: 30)
            )
            self.allUsers = response.users
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Friends
    func fetchFriends() async {
        isLoadingFriends = true
        errorMessage = nil
        defer { isLoadingFriends = false }
        
        do {
            let response: PaginatedFriendsResponse = try await APIClient.shared.request(
                .getFriends(page: 1, limit: 50)
            )
            self.friends = response.friends
            self.friendUserIds = Set(response.friends.map { $0.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Requests
    func fetchRequests() async {
        isLoadingRequests = true
        errorMessage = nil
        defer { isLoadingRequests = false }
        
        do {
            async let receivedCall: PaginatedRequestsResponse = APIClient.shared.request(.getReceivedRequests(page: 1, limit: 50))
            async let sentCall: PaginatedRequestsResponse = APIClient.shared.request(.getSentRequests(page: 1, limit: 50))
            
            let (rec, sent) = try await (receivedCall, sentCall)
            self.receivedRequests = rec.requests
            self.sentRequests = sent.requests
            self.sentRequestUserIds = Set(sent.requests.map { $0.receiver.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Request Actions
    func sendFriendRequest(to user: User) async {
        do {
            let req: FriendRequest = try await APIClient.shared.request(.sendFriendRequest(userId: user.id))
            withAnimation {
                sentRequestUserIds.insert(user.id)
                sentRequests.insert(req, at: 0)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func acceptRequest(_ request: FriendRequest) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.acceptFriendRequest(requestId: request.id))
            withAnimation {
                receivedRequests.removeAll { $0.id == request.id }
                friends.insert(request.sender, at: 0)
                friendUserIds.insert(request.sender.id)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func declineRequest(_ request: FriendRequest) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.declineFriendRequest(requestId: request.id))
            withAnimation {
                receivedRequests.removeAll { $0.id == request.id }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelRequest(_ request: FriendRequest) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.cancelFriendRequest(requestId: request.id))
            withAnimation {
                sentRequests.removeAll { $0.id == request.id }
                sentRequestUserIds.remove(request.receiver.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeFriend(user: User) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.removeFriend(friendId: user.id))
            withAnimation {
                friends.removeAll { $0.id == user.id }
                friendUserIds.remove(user.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
