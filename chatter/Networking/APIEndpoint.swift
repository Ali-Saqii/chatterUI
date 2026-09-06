//
//  APIEndpoint.swift
//  chatter
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint {
    // Auth
    case register
    case login
    case forgotPassword
    
    // Users
    case getMyProfile
    case getUserProfile(username: String)
    case searchUsers(query: String?, page: Int = 1, limit: Int = 20)
    case updateProfile
    case updateProfilePicture
    case updatePassword
    case deleteAccount
    
    // Friends
    case getFriends(page: Int = 1, limit: Int = 20)
    case getReceivedRequests(page: Int = 1, limit: Int = 20)
    case getSentRequests(page: Int = 1, limit: Int = 20)
    case sendFriendRequest(userId: String)
    case acceptFriendRequest(requestId: String)
    case declineFriendRequest(requestId: String)
    case cancelFriendRequest(requestId: String)
    case removeFriend(friendId: String)
    
    // Posts
    case getFeed(page: Int = 1, limit: Int = 20)
    case createPost
    case deletePost(postId: String)
    case getUserPosts(userId: String, page: Int = 1, limit: Int = 20)
    case getMyPosts(page: Int = 1, limit: Int = 20)
    
    // Placeholder endpoints for Likes & Comments for future one-line switchover
    case getComments(postId: String)
    case addComment(postId: String)
    case toggleLike(postId: String)
    
    var path: String {
        switch self {
        case .register:
            return "auth/register"
        case .login:
            return "auth/login"
        case .forgotPassword:
            return "auth/forgot-password"
            
        case .getMyProfile:
            return "users/me"
        case .getUserProfile(let username):
            return "users/\(username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username)"
        case .searchUsers:
            return "users"
        case .updateProfile:
            return "users/me"
        case .updateProfilePicture:
            return "users/profile-picture"
        case .updatePassword:
            return "users/update-password"
        case .deleteAccount:
            return "users/me"
            
        case .getFriends:
            return "friends"
        case .getReceivedRequests:
            return "friends/requests/received"
        case .getSentRequests:
            return "friends/requests/sent"
        case .sendFriendRequest(let userId):
            return "friends/request/\(userId)"
        case .acceptFriendRequest(let requestId):
            return "friends/accept/\(requestId)"
        case .declineFriendRequest(let requestId):
            return "friends/decline/\(requestId)"
        case .cancelFriendRequest(let requestId):
            return "friends/cancel/\(requestId)"
        case .removeFriend(let friendId):
            return "friends/\(friendId)"
            
        case .getFeed:
            return "posts/feed"
        case .createPost:
            return "posts/createPost"
        case .deletePost(let postId):
            return "posts/\(postId)"
        case .getUserPosts(let userId, _, _):
            return "posts/user/\(userId)"
        case .getMyPosts:
            return "posts/me"
            
        case .getComments(let postId):
            return "posts/\(postId)/comments"
        case .addComment(let postId):
            return "posts/\(postId)/comments"
        case .toggleLike(let postId):
            return "posts/\(postId)/like"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getMyProfile, .getUserProfile, .searchUsers,
             .getFriends, .getReceivedRequests, .getSentRequests,
             .getFeed, .getUserPosts, .getMyPosts, .getComments:
            return .get
            
        case .register, .login, .forgotPassword,
             .sendFriendRequest, .createPost, .addComment, .toggleLike:
            return .post
            
        case .updateProfile, .updateProfilePicture, .updatePassword,
             .acceptFriendRequest, .declineFriendRequest:
            return .patch
            
        case .deleteAccount, .cancelFriendRequest, .removeFriend, .deletePost:
            return .delete
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .register, .login, .forgotPassword:
            return false
        default:
            return true
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUsers(let query, let page, let limit):
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            if let query = query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                items.append(URLQueryItem(name: "search", value: query))
            }
            return items
            
        case .getFriends(let page, let limit),
             .getReceivedRequests(let page, let limit),
             .getSentRequests(let page, let limit),
             .getFeed(let page, let limit),
             .getMyPosts(let page, let limit):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            
        case .getUserPosts(_, let page, let limit):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            
        default:
            return nil
        }
    }
    
    func url(baseURL: String) -> URL? {
        var base = baseURL
        if !base.hasSuffix("/") {
            base += "/"
        }
        guard var components = URLComponents(string: base + path) else {
            return nil
        }
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }
}
