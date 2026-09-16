//
//  chatterTests.swift
//  chatterTests
//

import Foundation
import Testing
@testable import chatter

struct ModelDecodingTests {
    
    @Test func decodeUserWithStandardID() throws {
        let json = """
        {
            "id": "usr_123",
            "fullName": "Alice Smith",
            "username": "alices",
            "email": "alice@example.com",
            "bio": "Swift developer",
            "avatar": "http://example.com/avatar.jpg",
            "postsCount": 10,
            "friendsCount": 25
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)
        
        #expect(user.id == "usr_123")
        #expect(user.fullName == "Alice Smith")
        #expect(user.username == "alices")
        #expect(user.email == "alice@example.com")
        #expect(user.avatarURL == "http://example.com/avatar.jpg")
        #expect(user.postsCount == 10)
        #expect(user.friendsCount == 25)
    }
    
    @Test func decodeUserWithMongoID() throws {
        let json = """
        {
            "_id": "507f1f77bcf86cd799439011",
            "fullName": "Bob Jones",
            "username": "bobjones",
            "avatarURL": "http://example.com/bob.jpg"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)
        
        #expect(user.id == "507f1f77bcf86cd799439011")
        #expect(user.fullName == "Bob Jones")
        #expect(user.username == "bobjones")
        #expect(user.avatarURL == "http://example.com/bob.jpg")
    }
    
    @Test func decodePostWithMedia() throws {
        let json = """
        {
            "_id": "post_999",
            "author": {
                "id": "u1",
                "fullName": "Charlie",
                "username": "charlie"
            },
            "text": "Check out this mountain view!",
            "mediaUrl": "http://example.com/mountain.jpg",
            "mediaType": "image",
            "likesCount": 42,
            "commentsCount": 5,
            "isLikedByMe": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let post = try decoder.decode(Post.self, from: json)
        
        #expect(post.id == "post_999")
        #expect(post.author.username == "charlie")
        #expect(post.text == "Check out this mountain view!")
        #expect(post.mediaURL == "http://example.com/mountain.jpg")
        #expect(post.mediaType == .image)
        #expect(post.likesCount == 42)
        #expect(post.commentsCount == 5)
        #expect(post.isLikedByMe == true)
    }
    
    @Test func decodeFriendRequestStatus() throws {
        let json = """
        {
            "_id": "req_100",
            "sender": { "id": "u1", "fullName": "Alice", "username": "alice" },
            "receiver": { "id": "u2", "fullName": "Bob", "username": "bob" },
            "status": "accepted"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let req = try decoder.decode(FriendRequest.self, from: json)
        
        #expect(req.id == "req_100")
        #expect(req.sender.id == "u1")
        #expect(req.receiver.id == "u2")
        #expect(req.status == .accepted)
    }
}

@MainActor
struct AuthViewModelValidationTests {
    
    @Test func registerValidationEmptyFullName() async {
        let vm = AuthViewModel()
        let appState = AppState()
        
        vm.registerFullName = ""
        vm.registerUsername = "user"
        vm.registerEmail = "user@example.com"
        vm.registerPassword = "password123"
        
        await vm.register(appState: appState)
        #expect(vm.errorMessage == "Full name is required.")
    }
    
    @Test func registerValidationInvalidEmail() async {
        let vm = AuthViewModel()
        let appState = AppState()
        
        vm.registerFullName = "Jane Doe"
        vm.registerUsername = "janedoe"
        vm.registerEmail = "invalid-email"
        vm.registerPassword = "password123"
        
        await vm.register(appState: appState)
        #expect(vm.errorMessage == "Please enter a valid email address.")
    }
    
    @Test func registerValidationShortPassword() async {
        let vm = AuthViewModel()
        let appState = AppState()
        
        vm.registerFullName = "Jane Doe"
        vm.registerUsername = "janedoe"
        vm.registerEmail = "jane@example.com"
        vm.registerPassword = "123"
        
        await vm.register(appState: appState)
        #expect(vm.errorMessage == "Password must be at least 6 characters.")
    }
    
    @Test func loginValidationEmptyFields() async {
        let vm = AuthViewModel()
        let appState = AppState()
        
        vm.loginIdentifier = ""
        vm.loginPassword = ""
        
        await vm.login(appState: appState)
        #expect(vm.errorMessage == "Please enter your username or email.")
    }
}

@MainActor
struct SettingsViewModelValidationTests {
    
    @Test func updatePasswordMismatch() async {
        let vm = SettingsViewModel()
        let appState = AppState()
        
        vm.oldPassword = "currentPass"
        vm.newPassword = "newPassword1"
        vm.confirmNewPassword = "differentPassword"
        
        let success = await vm.updatePassword(appState: appState)
        #expect(success == false)
        #expect(vm.passwordErrorMessage == "New passwords do not match.")
    }
    
    @Test func updatePasswordTooShort() async {
        let vm = SettingsViewModel()
        let appState = AppState()
        
        vm.oldPassword = "currentPass"
        vm.newPassword = "123"
        vm.confirmNewPassword = "123"
        
        let success = await vm.updatePassword(appState: appState)
        #expect(success == false)
        #expect(vm.passwordErrorMessage == "New password must be at least 6 characters.")
    }
}

struct APIEndpointTests {
    
    @Test func endpointURLConstruction() {
        let baseURL = "http://localhost:5000/api/"
        
        let search = APIEndpoint.searchUsers(query: "swift", page: 2, limit: 15)
        let searchURL = search.url(baseURL: baseURL)
        #expect(searchURL?.absoluteString.contains("users?page=2&limit=15&search=swift") == true)
        
        let userProfile = APIEndpoint.getUserProfile(username: "john doe")
        let userURL = userProfile.url(baseURL: baseURL)
        #expect(userURL?.absoluteString.contains("users/john%20doe") == true)
        
        let comments = APIEndpoint.getComments(postId: "p123")
        #expect(comments.path == "posts/p123/comments")
        #expect(comments.method == .get)
        
        let toggleLike = APIEndpoint.toggleLike(postId: "p123")
        #expect(toggleLike.path == "posts/p123/like")
        #expect(toggleLike.method == .post)
    }
}

struct AppConfigTests {
    
    @Test func configBaseURLOverride() {
        let defaultURL = AppConfig.defaultBaseURL
        #expect(defaultURL == "http://localhost:5000/api/")
        
        AppConfig.baseURL = "https://staging.chatter.com/api/"
        #expect(AppConfig.baseURL == "https://staging.chatter.com/api/")
        
        // Reset to default
        AppConfig.baseURL = defaultURL
        #expect(AppConfig.baseURL == defaultURL)
    }
}
