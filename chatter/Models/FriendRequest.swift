//
//  FriendRequest.swift
//  chatter
//

import Foundation

enum FriendRequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case cancelled = "cancelled"
}

struct FriendRequest: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let sender: User
    let receiver: User
    var status: FriendRequestStatus
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case sender
        case receiver
        case status
        case createdAt
    }
    
    init(
        id: String,
        sender: User,
        receiver: User,
        status: FriendRequestStatus = .pending,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.sender = sender
        self.receiver = receiver
        self.status = status
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
        
        self.sender = try container.decode(User.self, forKey: .sender)
        self.receiver = try container.decode(User.self, forKey: .receiver)
        
        if let rawStatus = try? container.decode(String.self, forKey: .status),
           let parsedStatus = FriendRequestStatus(rawValue: rawStatus) {
            self.status = parsedStatus
        } else {
            self.status = .pending
        }
        
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sender, forKey: .sender)
        try container.encode(receiver, forKey: .receiver)
        try container.encode(status.rawValue, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

struct PaginatedRequestsResponse: Codable {
    let requests: [FriendRequest]
    let pagination: PaginationInfo
    
    init(requests: [FriendRequest] = [], pagination: PaginationInfo = PaginationInfo()) {
        self.requests = requests
        self.pagination = pagination
    }
}
