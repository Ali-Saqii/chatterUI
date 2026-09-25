//
//  AppNotification.swift
//  chatter
//

import Foundation

// MARK: - Notification Type

enum NotificationType: String, Codable, Equatable, Sendable {
    case message = "message"
    case friendRequest = "friend_request"
    case friendRequestAccepted = "friend_request_accepted"
    case like = "like"
    case comment = "comment"
    
    var icon: String {
        switch self {
        case .message:              return "bubble.left.fill"
        case .friendRequest:        return "person.badge.plus"
        case .friendRequestAccepted: return "person.2.fill"
        case .like:                 return "heart.fill"
        case .comment:              return "text.bubble.fill"
        }
    }
    
    var displayLabel: String {
        switch self {
        case .message:              return "Message"
        case .friendRequest:        return "Friend Request"
        case .friendRequestAccepted: return "Friend Accepted"
        case .like:                 return "Like"
        case .comment:              return "Comment"
        }
    }
}

// MARK: - Metadata

struct NotificationMetadata: Codable, Equatable, Sendable {
    let conversationId: String?
    
    init(conversationId: String? = nil) {
        self.conversationId = conversationId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.conversationId = try? container.decodeIfPresent(String.self, forKey: .conversationId)
    }
    
    enum CodingKeys: String, CodingKey {
        case conversationId
    }
}

// MARK: - Notification Model

struct AppNotification: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let recipient: String
    let actor: User
    let type: NotificationType
    let entityType: String?
    let entityId: String?
    let message: String
    let metadata: NotificationMetadata?
    var readAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var isRead: Bool { readAt != nil }
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case recipient
        case actor
        case type
        case entityType
        case entityId
        case message
        case metadata
        case readAt
        case createdAt
        case updatedAt
    }
    
    init(
        id: String,
        recipient: String,
        actor: User,
        type: NotificationType,
        entityType: String? = nil,
        entityId: String? = nil,
        message: String,
        metadata: NotificationMetadata? = nil,
        readAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recipient = recipient
        self.actor = actor
        self.type = type
        self.entityType = entityType
        self.entityId = entityId
        self.message = message
        self.metadata = metadata
        self.readAt = readAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id / _id
        if let idVal = try? container.decode(String.self, forKey: .id) {
            self.id = idVal
        } else if let mongoIdVal = try? container.decode(String.self, forKey: .mongoId) {
            self.id = mongoIdVal
        } else {
            self.id = UUID().uuidString
        }
        
        // recipient — string ID or populated User object
        if let recipientStr = try? container.decode(String.self, forKey: .recipient) {
            self.recipient = recipientStr
        } else if let recipientUser = try? container.decode(User.self, forKey: .recipient) {
            self.recipient = recipientUser.id
        } else {
            self.recipient = ""
        }
        
        self.actor = try container.decode(User.self, forKey: .actor)
        
        if let rawType = try? container.decode(String.self, forKey: .type),
           let parsed = NotificationType(rawValue: rawType) {
            self.type = parsed
        } else {
            self.type = .message
        }
        
        self.entityType = try? container.decodeIfPresent(String.self, forKey: .entityType)
        self.entityId = try? container.decodeIfPresent(String.self, forKey: .entityId)
        self.message = (try? container.decode(String.self, forKey: .message)) ?? ""
        self.metadata = try? container.decodeIfPresent(NotificationMetadata.self, forKey: .metadata)
        self.readAt = try? container.decodeIfPresent(Date.self, forKey: .readAt)
        self.createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recipient, forKey: .recipient)
        try container.encode(actor, forKey: .actor)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(entityType, forKey: .entityType)
        try container.encodeIfPresent(entityId, forKey: .entityId)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(readAt, forKey: .readAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Response Wrappers

/// GET /api/notification → data
struct NotificationListData: Codable {
    let notifications: [AppNotification]
    let unreadCount: Int
    let pagination: PaginationInfo
    
    init(notifications: [AppNotification] = [], unreadCount: Int = 0, pagination: PaginationInfo = PaginationInfo()) {
        self.notifications = notifications
        self.unreadCount = unreadCount
        self.pagination = pagination
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.notifications = (try? container.decode([AppNotification].self, forKey: .notifications)) ?? []
        self.unreadCount = (try? container.decode(Int.self, forKey: .unreadCount)) ?? 0
        self.pagination = (try? container.decode(PaginationInfo.self, forKey: .pagination)) ?? PaginationInfo()
    }
    
    enum CodingKeys: String, CodingKey {
        case notifications, unreadCount, pagination
    }
}

/// GET /api/notification/unread-count → data
struct UnreadCountData: Codable {
    let unreadCount: Int
    
    init(unreadCount: Int = 0) {
        self.unreadCount = unreadCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.unreadCount = (try? container.decode(Int.self, forKey: .unreadCount)) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case unreadCount
    }
}

/// PATCH /api/notification/read-all → data
struct MarkAllReadData: Codable {
    let updatedCount: Int
    
    init(updatedCount: Int = 0) {
        self.updatedCount = updatedCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.updatedCount = (try? container.decode(Int.self, forKey: .updatedCount)) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case updatedCount
    }
}

// MARK: - Mocks

extension AppNotification {
    static let mockList: [AppNotification] = [
        AppNotification(
            id: "n1",
            recipient: "mock_user_1",
            actor: User(id: "u2", fullName: "Alex Rivera", username: "arivera"),
            type: .like,
            message: "liked your post",
            createdAt: Date().addingTimeInterval(-300)
        ),
        AppNotification(
            id: "n2",
            recipient: "mock_user_1",
            actor: User(id: "u3", fullName: "Sophia Chen", username: "sophia_c"),
            type: .comment,
            message: "commented on your post",
            createdAt: Date().addingTimeInterval(-1800)
        ),
        AppNotification(
            id: "n3",
            recipient: "mock_user_1",
            actor: User(id: "u4", fullName: "Liam Davies", username: "liamd"),
            type: .friendRequest,
            message: "sent you a friend request",
            readAt: Date(),
            createdAt: Date().addingTimeInterval(-7200)
        ),
    ]
}
