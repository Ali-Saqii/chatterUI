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
        
        if let s = try? container.decode(User.self, forKey: .sender) {
            self.sender = s
        } else if let sId = try? container.decode(String.self, forKey: .sender) {
            self.sender = User(id: sId, fullName: "", username: "")
        } else {
            self.sender = User(id: "", fullName: "", username: "")
        }
        
        if let r = try? container.decode(User.self, forKey: .receiver) {
            self.receiver = r
        } else if let rId = try? container.decode(String.self, forKey: .receiver) {
            self.receiver = User(id: rId, fullName: "", username: "")
        } else {
            self.receiver = User(id: "", fullName: "", username: "")
        }
        
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
    static let mock = FriendRequest(
        id: "mock_req_1",
        sender: User.mockList[1],
        receiver: User.mock,
        status: .pending,
        createdAt: Date()
    )
    
    static let mockList: [FriendRequest] = [
        FriendRequest(
            id: "mock_req_1",
            sender: User.mockList[1],
            receiver: User.mock,
            status: .pending,
            createdAt: Date()
        ),
        FriendRequest(
            id: "mock_req_2",
            sender: User.mockList[2],
            receiver: User.mock,
            status: .pending,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        FriendRequest(
            id: "mock_req_3",
            sender: User.mock,
            receiver: User.mockList[3],
            status: .pending,
            createdAt: Date().addingTimeInterval(-7200)
        )
    ]
}

struct PaginatedRequestsResponse: Codable {
    let requests: [FriendRequest]
    let pagination: PaginationInfo
    
    init(requests: [FriendRequest] = [], pagination: PaginationInfo = PaginationInfo()) {
        self.requests = requests
        self.pagination = pagination
    }
}
