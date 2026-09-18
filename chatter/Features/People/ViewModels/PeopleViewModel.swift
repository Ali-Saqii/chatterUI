//
//  PeopleViewModel.swift
//  chatter
//

import SwiftUI
import Combine

enum RequestFilter: String, CaseIterable, Identifiable {
    case received = "Friend Requests"
    case sent = "Sent Requests"
    
    var id: String { rawValue }
}

@MainActor
final class PeopleViewModel: ObservableObject {
    @Published var selectedTab: Int = 0 // 0: All People, 1: Friends, 2: Requests
    @Published var requestFilter: RequestFilter = .received
    
    var currentUserId: String?
    
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
    
    // MARK: - Dispatcher for Query or Tab Change
    func onSearchQueryOrTabChanged() async {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            switch selectedTab {
            case 0:
                await fetchAllUsers()
            case 1:
                await fetchFriends()
            case 2:
                await fetchRequests()
            default:
                break
            }
        } else {
            switch selectedTab {
            case 0:
                await searchPeople(query: trimmed)
            case 1:
                await searchFriends(query: trimmed)
            case 2:
                await searchFriendRequests(query: trimmed)
            default:
                break
            }
        }
    }
    
    // Backwards-compatible alias
    func searchUsers() async {
        await onSearchQueryOrTabChanged()
    }
    
    // MARK: - All Users (Default without query)
    func fetchAllUsers() async {
        isLoadingUsers = true
        errorMessage = nil
        defer { isLoadingUsers = false }
        
        do {
            let response: PaginatedUsersResponse = try await APIClient.shared.request(
                .getAllUsers(page: 1, limit: 50)
            )
            self.allUsers = response.users
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Search People (With query)
    func searchPeople(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await fetchAllUsers()
            return
        }
        
        isLoadingUsers = true
        errorMessage = nil
        defer { isLoadingUsers = false }
        
        do {
            let response: PaginatedUsersResponse = try await APIClient.shared.request(
                .searchPeople(query: trimmed, page: 1, limit: 50)
            )
            self.allUsers = response.users
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Friends (Default without query)
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
    
    // MARK: - Search Friends (With query)
    func searchFriends(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await fetchFriends()
            return
        }
        
        isLoadingFriends = true
        errorMessage = nil
        defer { isLoadingFriends = false }
        
        do {
            let response: PaginatedFriendsResponse = try await APIClient.shared.request(
                .searchFriends(query: trimmed, page: 1, limit: 50)
            )
            self.friends = response.friends
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Requests (Default without query)
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
    
    // MARK: - Search Friend Requests (With query)
    func searchFriendRequests(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await fetchRequests()
            return
        }
        
        isLoadingRequests = true
        errorMessage = nil
        defer { isLoadingRequests = false }
        
        do {
            let response: PaginatedRequestsResponse = try await APIClient.shared.request(
                .searchFriendRequests(query: trimmed, page: 1, limit: 50)
            )
            
            if let myId = currentUserId, !myId.isEmpty {
                self.receivedRequests = response.requests.filter { $0.receiver.id == myId || ($0.sender.id != myId && !$0.sender.id.isEmpty) }
                self.sentRequests = response.requests.filter { $0.sender.id == myId }
            } else {
                self.receivedRequests = response.requests
                self.sentRequests = response.requests
            }
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
