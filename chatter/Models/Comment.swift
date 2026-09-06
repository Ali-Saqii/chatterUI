//
//  Comment.swift
//  chatter
//

import Foundation

struct Comment: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let post: String
    let author: User
    let text: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case post
        case author
        case text
        case createdAt
    }
    
    init(
        id: String = UUID().uuidString,
        post: String,
        author: User,
        text: String,
        createdAt: Date? = Date()
    ) {
        self.id = id
        self.post = post
        self.author = author
        self.text = text
        self.createdAt = createdAt
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
        
        self.post = (try? container.decode(String.self, forKey: .post)) ?? ""
        self.author = try container.decode(User.self, forKey: .author)
        self.text = (try? container.decode(String.self, forKey: .text)) ?? ""
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(post, forKey: .post)
        try container.encode(author, forKey: .author)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
    
    // Mocks for development until backend activates comments endpoint
    static func mockComments(for postId: String) -> [Comment] {
        [
            Comment(
                id: "c1",
                post: postId,
                author: User(id: "u2", fullName: "Alex Rivera", username: "arivera", bio: "Tech & Coffee"),
                text: "This looks amazing! Great update 🚀",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Comment(
                id: "c2",
                post: postId,
                author: User(id: "u3", fullName: "Sophia Chen", username: "sophia_c", bio: "SwiftUI explorer"),
                text: "Love the clean aesthetics and layout!",
                createdAt: Date().addingTimeInterval(-1800)
            ),
            Comment(
                id: "c3",
                post: postId,
                author: User(id: "u4", fullName: "Liam Davies", username: "liamd", bio: "Photographer"),
                text: "Awesome shot, which camera did you use?",
                createdAt: Date().addingTimeInterval(-600)
            )
        ]
    }
}
