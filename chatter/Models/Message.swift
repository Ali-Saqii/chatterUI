//
//  Message.swift
//  chatter
//

import Foundation

struct MessageSender: Codable, Identifiable, Hashable {
    let id: String
    let username: String?
    let avatarURL: String?
    
    init(id: String, username: String? = nil, avatarURL: String? = nil) {
        self.id = id
        self.username = username
        self.avatarURL = avatarURL
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.id = (try? container.decode(String.self, forKey: .id))
                ?? (try? container.decode(String.self, forKey: .mongoId))
                ?? ""
            self.username = try? container.decode(String.self, forKey: .username)
            self.avatarURL = (try? container.decode(String.self, forKey: .avatarURL))
                ?? (try? container.decode(String.self, forKey: .avatarUrlAlt))
        } else if let singleContainer = try? decoder.singleValueContainer(), let stringId = try? singleContainer.decode(String.self) {
            self.id = stringId
            self.username = nil
            self.avatarURL = nil
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid MessageSender"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case username
        case avatarURL
        case avatarUrlAlt = "avatarUrl"
    }
}

struct Message: Codable, Identifiable, Hashable {
    let id: String
    let conversation: String
    let sender: MessageSender
    let text: String?
    let mediaUrl: String?
    let readBy: [String]?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case conversation
        case sender
        case text
        case mediaUrl
        case readBy
        case createdAt
        case updatedAt
    }
    
    init(
        id: String,
        conversation: String,
        sender: MessageSender,
        text: String? = nil,
        mediaUrl: String? = nil,
        readBy: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.conversation = conversation
        self.sender = sender
        self.text = text
        self.mediaUrl = mediaUrl
        self.readBy = readBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: .mongoId))
            ?? UUID().uuidString
        self.conversation = (try? container.decode(String.self, forKey: .conversation)) ?? ""
        
        if let senderObj = try? container.decode(MessageSender.self, forKey: .sender) {
            self.sender = senderObj
        } else if let senderId = try? container.decode(String.self, forKey: .sender) {
            self.sender = MessageSender(id: senderId)
        } else {
            self.sender = MessageSender(id: "")
        }
        
        self.text = try? container.decodeIfPresent(String.self, forKey: .text)
        self.mediaUrl = try? container.decodeIfPresent(String.self, forKey: .mediaUrl)
        self.readBy = try? container.decodeIfPresent([String].self, forKey: .readBy)
        self.createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(conversation, forKey: .conversation)
        try container.encode(sender, forKey: .sender)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(mediaUrl, forKey: .mediaUrl)
        try container.encodeIfPresent(readBy, forKey: .readBy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    func isFromUser(userId: String?) -> Bool {
        guard let userId = userId else { return false }
        return sender.id == userId
    }
}

struct MessagePagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, limit, total
    }
    
    init(page: Int = 1, limit: Int = 20, total: Int = 0) {
        self.page = page
        self.limit = limit
        self.total = total
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = (try? container.decode(Int.self, forKey: .page)) ?? 1
        self.limit = (try? container.decode(Int.self, forKey: .limit)) ?? 20
        self.total = (try? container.decode(Int.self, forKey: .total)) ?? 0
    }
}

struct MessagesData: Codable {
    let messages: [Message]
    let pagination: MessagePagination
    
    enum CodingKeys: String, CodingKey {
        case messages, pagination
    }
    
    init(messages: [Message] = [], pagination: MessagePagination = MessagePagination()) {
        self.messages = messages
        self.pagination = pagination
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.messages = (try? container.decode([Message].self, forKey: .messages)) ?? []
        self.pagination = (try? container.decode(MessagePagination.self, forKey: .pagination)) ?? MessagePagination()
    }
}

struct SendMessageRequest: Encodable {
    let text: String?
    let mediaUrl: String?
}
