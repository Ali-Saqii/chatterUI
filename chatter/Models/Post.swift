//
//  Post.swift
//  chatter
//

import Foundation

enum MediaType: String, Codable {
    case none = "none"
    case image = "image"
    case video = "video"
}

struct Post: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let author: User
    let text: String?
    let mediaURL: String?
    let mediaPublicId: String?
    let mediaType: MediaType
    var likesCount: Int
    var commentsCount: Int
    let createdAt: Date?
    var isLikedByMe: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case author
        case text
        case mediaURL
        case mediaUrl
        case mediaPublicId
        case mediaType
        case likesCount
        case commentsCount
        case createdAt
        case isLikedByMe
    }
    
    init(
        id: String,
        author: User,
        text: String?,
        mediaURL: String? = nil,
        mediaPublicId: String? = nil,
        mediaType: MediaType = .none,
        likesCount: Int = 0,
        commentsCount: Int = 0,
        createdAt: Date? = nil,
        isLikedByMe: Bool = false
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.mediaURL = mediaURL
        self.mediaPublicId = mediaPublicId
        self.mediaType = mediaType
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.createdAt = createdAt
        self.isLikedByMe = isLikedByMe
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idVal = try? container.decode(String.self, forKey: .id) {
            self.id = idVal
        } else if let mongoIdVal = try? container.decode(String.self, forKey: .mongoId) {
            self.id = mongoIdVal
        } else {
            self.id = UUID().uuidString
        }
        
        self.author = try container.decode(User.self, forKey: .author)
        self.text = try? container.decodeIfPresent(String.self, forKey: .text)
        
        if let mUrl = try? container.decodeIfPresent(String.self, forKey: .mediaURL) {
            self.mediaURL = mUrl
        } else if let mUrlAlt = try? container.decodeIfPresent(String.self, forKey: .mediaUrl) {
            self.mediaURL = mUrlAlt
        } else {
            self.mediaURL = nil
        }
        
        self.mediaPublicId = try? container.decodeIfPresent(String.self, forKey: .mediaPublicId)
        
        if let rawMediaType = try? container.decodeIfPresent(String.self, forKey: .mediaType),
           let type = MediaType(rawValue: rawMediaType) {
            self.mediaType = type
        } else {
            self.mediaType = .none
        }
        
        self.likesCount = (try? container.decodeIfPresent(Int.self, forKey: .likesCount)) ?? 0
        self.commentsCount = (try? container.decodeIfPresent(Int.self, forKey: .commentsCount)) ?? 0
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.isLikedByMe = (try? container.decodeIfPresent(Bool.self, forKey: .isLikedByMe)) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(author, forKey: .author)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(mediaURL, forKey: .mediaURL)
        try container.encodeIfPresent(mediaPublicId, forKey: .mediaPublicId)
        try container.encode(mediaType.rawValue, forKey: .mediaType)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encode(commentsCount, forKey: .commentsCount)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(isLikedByMe, forKey: .isLikedByMe)
    }
}

struct PaginatedPostsResponse: Codable {
    let posts: [Post]
    let pagination: PaginationInfo
    
    init(posts: [Post] = [], pagination: PaginationInfo = PaginationInfo()) {
        self.posts = posts
        self.pagination = pagination
    }
}

extension Post {
    static let mock = Post(
        id: "mock_post_1",
        author: User.mock,
        text: "Just shipped the complete SwiftUI frontend for Chatter! Sleek dark/light mode, custom animations, and clean MVVM architecture 📱🚀",
        mediaURL: nil,
        mediaPublicId: nil,
        mediaType: .none,
        likesCount: 38,
        commentsCount: 9,
        createdAt: Date().addingTimeInterval(-1800),
        isLikedByMe: false
    )
    
    static let mockList: [Post] = [
        Post(
            id: "p1",
            author: User.mock,
            text: "Excited to launch our new social media platform! Join the conversation and connect with creators worldwide.",
            mediaURL: nil,
            mediaType: .none,
            likesCount: 52,
            commentsCount: 14,
            createdAt: Date().addingTimeInterval(-3600),
            isLikedByMe: true
        ),
        Post(
            id: "p2",
            author: User.mockList[1],
            text: "Golden hour in the mountains today. Nothing beats nature's lighting.",
            mediaURL: "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
            mediaType: .image,
            likesCount: 128,
            commentsCount: 23,
            createdAt: Date().addingTimeInterval(-7200),
            isLikedByMe: false
        ),
        Post(
            id: "p3",
            author: User.mockList[2],
            text: "Working on some exciting new SwiftUI view modifiers and animations. The canvas previews make iterating so fast!",
            mediaURL: nil,
            mediaType: .none,
            likesCount: 41,
            commentsCount: 6,
            createdAt: Date().addingTimeInterval(-14400),
            isLikedByMe: false
        )
    ]
}

