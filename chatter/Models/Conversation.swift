//
//  Conversation.swift
//  chatter
//

import Foundation

struct ConversationParticipant: Codable, Identifiable, Hashable {
    let id: String
    var username: String?
    var email: String?
    var avatarURL: String?
    
    init(id: String, username: String? = nil, email: String? = nil, avatarURL: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.id = (try? container.decode(String.self, forKey: .id))
                ?? (try? container.decode(String.self, forKey: .mongoId))
                ?? ""
            self.username = try? container.decode(String.self, forKey: .username)
            self.email = try? container.decode(String.self, forKey: .email)
            self.avatarURL = (try? container.decode(String.self, forKey: .avatarURL))
                ?? (try? container.decode(String.self, forKey: .avatarUrlAlt))
        } else if let singleContainer = try? decoder.singleValueContainer(), let stringId = try? singleContainer.decode(String.self) {
            self.id = stringId
            self.username = nil
            self.email = nil
            self.avatarURL = nil
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid ConversationParticipant"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case username
        case email
        case avatarURL
        case avatarUrlAlt = "avatarUrl"
    }
}

struct Conversation: Codable, Identifiable, Hashable {
    let id: String
    var participants: [ConversationParticipant]
    let isGroup: Bool
    let groupName: String?
    let groupAdmin: String?
    var lastMessage: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case participants
        case isGroup
        case groupName
        case groupAdmin
        case lastMessage
        case createdAt
        case updatedAt
    }
    
    init(
        id: String,
        participants: [ConversationParticipant] = [],
        isGroup: Bool = false,
        groupName: String? = nil,
        groupAdmin: String? = nil,
        lastMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.participants = participants
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupAdmin = groupAdmin
        self.lastMessage = lastMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: .mongoId))
            ?? UUID().uuidString
            
        self.participants = (try? container.decode([ConversationParticipant].self, forKey: .participants)) ?? []
        self.isGroup = (try? container.decode(Bool.self, forKey: .isGroup)) ?? false
        self.groupName = try? container.decodeIfPresent(String.self, forKey: .groupName)
        
        // Handle groupAdmin: backend may return a string ID OR populated User object
        if let adminId = try? container.decodeIfPresent(String.self, forKey: .groupAdmin) {
            self.groupAdmin = adminId
        } else if let adminParticipant = try? container.decodeIfPresent(ConversationParticipant.self, forKey: .groupAdmin) {
            self.groupAdmin = adminParticipant.id
        } else {
            self.groupAdmin = nil
        }
        
        // Handle lastMessage: backend may return string, or string ID, or null
        if let lastMsgStr = try? container.decodeIfPresent(String.self, forKey: .lastMessage) {
            self.lastMessage = lastMsgStr
        } else {
            self.lastMessage = nil
        }
        
        self.createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(participants, forKey: .participants)
        try container.encode(isGroup, forKey: .isGroup)
        try container.encodeIfPresent(groupName, forKey: .groupName)
        try container.encodeIfPresent(groupAdmin, forKey: .groupAdmin)
        try container.encodeIfPresent(lastMessage, forKey: .lastMessage)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    func otherParticipant(currentUserId: String?) -> ConversationParticipant? {
        guard let currentUserId = currentUserId else {
            return participants.first
        }
        return participants.first(where: { $0.id != currentUserId }) ?? participants.first
    }
    
    func displayTitle(currentUserId: String?) -> String {
        if isGroup {
            return groupName ?? "Group Chat"
        }
        if let other = otherParticipant(currentUserId: currentUserId) {
            if let uname = other.username, !uname.isEmpty {
                return uname
            }
            return "Chat"
        }
        return "Chat"
    }
    
    func displayAvatarURL(currentUserId: String?) -> String? {
        if isGroup { return nil }
        return otherParticipant(currentUserId: currentUserId)?.avatarURL
    }
}

struct ConversationPagination: Codable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.total = (try? container.decode(Int.self, forKey: .total)) ?? 0
        self.page = (try? container.decode(Int.self, forKey: .page)) ?? 1
        self.limit = (try? container.decode(Int.self, forKey: .limit)) ?? 20
        self.totalPages = (try? container.decode(Int.self, forKey: .totalPages)) ?? 1
    }
}

struct ConversationListData: Codable {
    let conversations: [Conversation]
    let pagination: ConversationPagination
}

struct CreateConversationRequest: Encodable {
    let participantIds: [String]
    let isGroup: Bool
    let groupName: String?
}
