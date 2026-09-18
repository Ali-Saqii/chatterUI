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
    case put = "PUT"
}

enum APIEndpoint {
    // Auth
    case register
    case login
    case forgotPassword
    
    // Users
    case getMyProfile
    case getUserProfile(username: String)
    case getAllUsers(page: Int = 1, limit: Int = 20)
    case searchPeople(query: String, page: Int = 1, limit: Int = 20)
    case searchUsers(query: String?, page: Int = 1, limit: Int = 20)
    case updateProfile
    case updateProfilePicture
    case updatePassword
    case deleteAccount
    
    // Friends
    case getFriends(page: Int = 1, limit: Int = 20)
    case searchFriends(query: String, page: Int = 1, limit: Int = 20)
    case getReceivedRequests(page: Int = 1, limit: Int = 20)
    case getSentRequests(page: Int = 1, limit: Int = 20)
    case searchFriendRequests(query: String, page: Int = 1, limit: Int = 20)
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
    
    // Comments & Likes — backend: /api/comment/...
    case getComments(postId: String)
    case addComment(postId: String)
    case deleteComment(commentId: String)
    case likePost(postId: String)
    case unlikePost(postId: String)
    
    var path: String {
        switch self {
        case .register:
            return "auth/register"
        case .login:
            return "auth/login"
        case .forgotPassword:
            return "auth/forgot-password"

        // Backend: /api/user/...
        case .getMyProfile:
            return "user/profile"
        case .getUserProfile(let username):
            return "user/\(username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username)"
        case .getAllUsers:
            return "friend/allUsers"
        case .searchPeople:
            return "friend/searchPeople"
        case .searchUsers(let query, _, _):
            if let q = query, !q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "friend/searchPeople"
            }
            return "friend/allUsers"
        case .updateProfile:
            return "user/updateProfile"
        case .updateProfilePicture:
            return "user/profilePicture"
        case .updatePassword:
            return "user/updatePassword"
        case .deleteAccount:
            return "user/delete"

        // Backend: /api/friend/...
        case .getFriends:
            return "friend/friendsList"
        case .searchFriends:
            return "friend/searchFriends"
        case .getReceivedRequests:
            return "friend/friendRequests"
        case .getSentRequests:
            return "friend/sentRequests"
        case .searchFriendRequests:
            return "friend/searchFriendRequests"
        case .sendFriendRequest(let userId):
            return "friend/sendRequest/\(userId)"
        case .acceptFriendRequest(let requestId):
            return "friend/acceptRequest/\(requestId)"
        case .declineFriendRequest(let requestId):
            return "friend/declineRequest/\(requestId)"
        case .cancelFriendRequest(let requestId):
            return "friend/cancelRequest/\(requestId)"
        case .removeFriend(let friendId):
            return "friend/deleteFriend/\(friendId)"

        // Backend: /api/post/...
        case .getFeed:
            return "post/feed"
        case .createPost:
            return "post/createPost"
        case .deletePost(let postId):
            return "post/deletePost/\(postId)"
        case .getUserPosts(let userId, _, _):
            return "post/userPosts/\(userId)"
        case .getMyPosts:
            return "post/myPosts"

        // Backend: /api/comment/...
        case .getComments(let postId):
            return "comment/getComments/\(postId)"
        case .addComment(let postId):
            return "comment/createComment/\(postId)"
        case .deleteComment(let commentId):
            return "comment/deleteComment/\(commentId)"
        case .likePost(let postId):
            return "comment/likePost/\(postId)"
        case .unlikePost(let postId):
            return "comment/unlikePost/\(postId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getMyProfile, .getUserProfile, .getAllUsers, .searchPeople, .searchUsers,
             .getFriends, .searchFriends, .getReceivedRequests, .getSentRequests, .searchFriendRequests,
             .getFeed, .getUserPosts, .getMyPosts, .getComments:
            return .get
            
        case .register, .login, .forgotPassword,
             .sendFriendRequest, .acceptFriendRequest, .declineFriendRequest, .cancelFriendRequest,
             .createPost, .addComment, .likePost, .unlikePost:
            return .post
            
        case .updateProfile, .updatePassword:
            return .put
            
        case .updateProfilePicture:
            return .patch
            
        case .deleteAccount, .removeFriend, .deletePost, .deleteComment:
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
        case .getAllUsers(let page, let limit):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            
        case .searchPeople(let query, let page, let limit),
             .searchFriends(let query, let page, let limit),
             .searchFriendRequests(let query, let page, let limit):
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items.append(URLQueryItem(name: "q", value: trimmed))
            }
            return items
            
        case .searchUsers(let query, let page, let limit):
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            if let query = query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                items.append(URLQueryItem(name: "q", value: query))  // backend uses req.query.q
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
