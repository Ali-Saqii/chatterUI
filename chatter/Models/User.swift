//
//  User.swift
//  chatter
//

import Foundation

struct PaginationInfo: Codable, Equatable, Sendable {
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case total, page, limit, totalPages
    }
    
    init(total: Int = 0, page: Int = 1, limit: Int = 20, totalPages: Int = 1) {
        self.total = total
        self.page = page
        self.limit = limit
        self.totalPages = totalPages
    }
}

struct User: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var fullName: String
    var username: String
    var email: String?
    var bio: String?
    var avatarURL: String?
    var postsCount: Int
    var friendsCount: Int
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case fullName
        case username
        case email
        case bio
        case avatarURL = "avatar"
        case avatarURLAlt = "avatarURL"
        case postsCount
        case friendsCount
        case createdAt
    }
    
    init(
        id: String,
        fullName: String,
        username: String,
        email: String? = nil,
        bio: String? = nil,
        avatarURL: String? = nil,
        postsCount: Int = 0,
        friendsCount: Int = 0,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.email = email
        self.bio = bio
        self.avatarURL = avatarURL
        self.postsCount = postsCount
        self.friendsCount = friendsCount
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id or _id
        if let idVal = try? container.decode(String.self, forKey: .id) {
            self.id = idVal
        } else if let mongoIdVal = try? container.decode(String.self, forKey: .mongoId) {
            self.id = mongoIdVal
        } else {
            self.id = UUID().uuidString
        }
        
        self.fullName = (try? container.decode(String.self, forKey: .fullName)) ?? ""
        self.username = (try? container.decode(String.self, forKey: .username)) ?? ""
        self.email = try? container.decodeIfPresent(String.self, forKey: .email)
        self.bio = try? container.decodeIfPresent(String.self, forKey: .bio)
        
        // Handle avatar / avatarURL
        if let avatar = try? container.decodeIfPresent(String.self, forKey: .avatarURL) {
            self.avatarURL = avatar
        } else if let avatarAlt = try? container.decodeIfPresent(String.self, forKey: .avatarURLAlt) {
            self.avatarURL = avatarAlt
        } else {
            self.avatarURL = nil
        }
        
        self.postsCount = (try? container.decodeIfPresent(Int.self, forKey: .postsCount)) ?? 0
        self.friendsCount = (try? container.decodeIfPresent(Int.self, forKey: .friendsCount)) ?? 0
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encode(postsCount, forKey: .postsCount)
        try container.encode(friendsCount, forKey: .friendsCount)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

// Responses
struct AuthResponseData: Codable {
    let token: String?
    let user: User?
}

struct PaginatedUsersResponse: Codable {
    let users: [User]
    let pagination: PaginationInfo
    
    enum CodingKeys: String, CodingKey {
        case users
        case people
        case pagination
    }
    
    init(users: [User] = [], pagination: PaginationInfo = PaginationInfo()) {
        self.users = users
        self.pagination = pagination
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let userList = try? container.decode([User].self, forKey: .users) {
            self.users = userList
        } else if let peopleList = try? container.decode([User].self, forKey: .people) {
            self.users = peopleList
        } else {
            self.users = []
        }
        self.pagination = (try? container.decode(PaginationInfo.self, forKey: .pagination)) ?? PaginationInfo()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(users, forKey: .users)
        try container.encode(pagination, forKey: .pagination)
    }
}

struct PaginatedFriendsResponse: Codable {
    let friends: [User]
    let pagination: PaginationInfo
    
    init(friends: [User] = [], pagination: PaginationInfo = PaginationInfo()) {
        self.friends = friends
        self.pagination = pagination
    }
}

enum FriendActionState: Equatable {
    case addFriend
    case requestSent(requestId: String?)
    case requestReceived(requestId: String)
    case friends(friendId: String?)
    case editProfile
    case loading
}

extension User {
    static let mock = User(
        id: "mock_user_1",
        fullName: "Sarah Connor",
        username: "sarahc",
        email: "sarah@example.com",
        bio: "Designing the future of social technology 🚀 | Coffee & Swift enthusiast",
        avatarURL: nil,
        postsCount: 24,
        friendsCount: 142,
        createdAt: Date()
    )
    
    static let mockList: [User] = [
        User(id: "u1", fullName: "Sarah Connor", username: "sarahc", bio: "Tech & Design", postsCount: 12, friendsCount: 54),
        User(id: "u2", fullName: "Alex Rivera", username: "arivera", bio: "Photographer & Developer", postsCount: 30, friendsCount: 89),
        User(id: "u3", fullName: "Sophia Chen", username: "sophia_c", bio: "SwiftUI explorer", postsCount: 18, friendsCount: 110),
        User(id: "u4", fullName: "Liam Davies", username: "liamd", bio: "Music lover & sound designer", postsCount: 7, friendsCount: 42)
    ]
}

