//
//  CoreDataEntities.swift
//  chatter
//

import Foundation
import CoreData

// MARK: - CDUser

@objc(CDUser)
public class CDUser: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var fullName: String?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var bio: String?
    @NSManaged public var avatarURL: String?
    @NSManaged public var postsCount: Int32
    @NSManaged public var friendsCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var isCurrentUser: Bool
    @NSManaged public var isFriend: Bool
    @NSManaged public var cachedAt: Date?
    
    func toUser() -> User {
        User(
            id: id ?? UUID().uuidString,
            fullName: fullName ?? "Unknown User",
            username: username ?? "user",
            email: email,
            bio: bio,
            avatarURL: avatarURL,
            postsCount: Int(postsCount),
            friendsCount: Int(friendsCount),
            createdAt: createdAt
        )
    }
    
    func update(from user: User, isCurrentUser: Bool = false, isFriend: Bool = false) {
        self.id = user.id
        self.fullName = user.fullName
        self.username = user.username
        self.email = user.email
        self.bio = user.bio
        self.avatarURL = user.avatarURL
        self.postsCount = Int32(user.postsCount)
        self.friendsCount = Int32(user.friendsCount)
        self.createdAt = user.createdAt
        self.isCurrentUser = isCurrentUser
        self.isFriend = isFriend
        self.cachedAt = Date()
    }
}

// MARK: - CDPost

@objc(CDPost)
public class CDPost: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var text: String?
    @NSManaged public var mediaURL: String?
    @NSManaged public var mediaPublicId: String?
    @NSManaged public var mediaType: String?
    @NSManaged public var likesCount: Int32
    @NSManaged public var commentsCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var isLikedByMe: Bool
    @NSManaged public var cachedAt: Date?
    
    // Embedded Author
    @NSManaged public var authorId: String?
    @NSManaged public var authorFullName: String?
    @NSManaged public var authorUsername: String?
    @NSManaged public var authorEmail: String?
    @NSManaged public var authorBio: String?
    @NSManaged public var authorAvatarURL: String?
    @NSManaged public var authorPostsCount: Int32
    @NSManaged public var authorFriendsCount: Int32
    
    func toPost() -> Post {
        let author = User(
            id: authorId ?? "unknown",
            fullName: authorFullName ?? "Unknown Author",
            username: authorUsername ?? "author",
            email: authorEmail,
            bio: authorBio,
            avatarURL: authorAvatarURL,
            postsCount: Int(authorPostsCount),
            friendsCount: Int(authorFriendsCount),
            createdAt: nil
        )
        
        let type = MediaType(rawValue: mediaType ?? "none") ?? .none
        
        return Post(
            id: id ?? UUID().uuidString,
            author: author,
            text: text,
            mediaURL: mediaURL,
            mediaPublicId: mediaPublicId,
            mediaType: type,
            likesCount: Int(likesCount),
            commentsCount: Int(commentsCount),
            createdAt: createdAt,
            isLikedByMe: isLikedByMe
        )
    }
    
    func update(from post: Post) {
        self.id = post.id
        self.text = post.text
        self.mediaURL = post.mediaURL
        self.mediaPublicId = post.mediaPublicId
        self.mediaType = post.mediaType.rawValue
        self.likesCount = Int32(post.likesCount)
        self.commentsCount = Int32(post.commentsCount)
        self.createdAt = post.createdAt
        self.isLikedByMe = post.isLikedByMe
        self.cachedAt = Date()
        
        self.authorId = post.author.id
        self.authorFullName = post.author.fullName
        self.authorUsername = post.author.username
        self.authorEmail = post.author.email
        self.authorBio = post.author.bio
        self.authorAvatarURL = post.author.avatarURL
        self.authorPostsCount = Int32(post.author.postsCount)
        self.authorFriendsCount = Int32(post.author.friendsCount)
    }
}

// MARK: - CDComment

@objc(CDComment)
public class CDComment: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var postId: String?
    @NSManaged public var text: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var cachedAt: Date?
    
    // Embedded Author
    @NSManaged public var authorId: String?
    @NSManaged public var authorFullName: String?
    @NSManaged public var authorUsername: String?
    @NSManaged public var authorAvatarURL: String?
    
    func toComment() -> Comment {
        let author = User(
            id: authorId ?? "unknown",
            fullName: authorFullName ?? "User",
            username: authorUsername ?? "user",
            avatarURL: authorAvatarURL
        )
        return Comment(
            id: id ?? UUID().uuidString,
            post: postId ?? "",
            author: author,
            text: text ?? "",
            createdAt: createdAt
        )
    }
    
    func update(from comment: Comment) {
        self.id = comment.id
        self.postId = comment.post
        self.text = comment.text
        self.createdAt = comment.createdAt
        self.cachedAt = Date()
        
        self.authorId = comment.author.id
        self.authorFullName = comment.author.fullName
        self.authorUsername = comment.author.username
        self.authorAvatarURL = comment.author.avatarURL
    }
}

// MARK: - CDConversation

@objc(CDConversation)
public class CDConversation: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var isGroup: Bool
    @NSManaged public var groupName: String?
    @NSManaged public var groupAdmin: String?
    @NSManaged public var lastMessage: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cachedAt: Date?
    @NSManaged public var participantsJSON: String?
    
    func toConversation() -> Conversation {
        var participants: [ConversationParticipant] = []
        if let jsonStr = participantsJSON, let data = jsonStr.data(using: .utf8) {
            participants = (try? JSONDecoder().decode([ConversationParticipant].self, from: data)) ?? []
        }
        
        return Conversation(
            id: id ?? UUID().uuidString,
            participants: participants,
            isGroup: isGroup,
            groupName: groupName,
            groupAdmin: groupAdmin,
            lastMessage: lastMessage,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    func update(from conversation: Conversation) {
        self.id = conversation.id
        self.isGroup = conversation.isGroup
        self.groupName = conversation.groupName
        self.groupAdmin = conversation.groupAdmin
        self.lastMessage = conversation.lastMessage
        self.createdAt = conversation.createdAt
        self.updatedAt = conversation.updatedAt
        self.cachedAt = Date()
        
        if let data = try? JSONEncoder().encode(conversation.participants),
           let jsonStr = String(data: data, encoding: .utf8) {
            self.participantsJSON = jsonStr
        }
    }
}

// MARK: - CDMessage

@objc(CDMessage)
public class CDMessage: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var conversationId: String?
    @NSManaged public var senderId: String?
    @NSManaged public var senderUsername: String?
    @NSManaged public var senderAvatarURL: String?
    @NSManaged public var text: String?
    @NSManaged public var mediaUrl: String?
    @NSManaged public var readByJSON: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cachedAt: Date?
    
    func toMessage() -> Message {
        var readByList: [String]? = nil
        if let json = readByJSON, let data = json.data(using: .utf8) {
            readByList = try? JSONDecoder().decode([String].self, from: data)
        }
        
        let sender = MessageSender(
            id: senderId ?? "",
            username: senderUsername,
            avatarURL: senderAvatarURL
        )
        
        return Message(
            id: id ?? UUID().uuidString,
            conversation: conversationId ?? "",
            sender: sender,
            text: text,
            mediaUrl: mediaUrl,
            readBy: readByList,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    func update(from message: Message) {
        self.id = message.id
        self.conversationId = message.conversation
        self.senderId = message.sender.id
        self.senderUsername = message.sender.username
        self.senderAvatarURL = message.sender.avatarURL
        self.text = message.text
        self.mediaUrl = message.mediaUrl
        self.createdAt = message.createdAt
        self.updatedAt = message.updatedAt
        self.cachedAt = Date()
        
        if let readBy = message.readBy,
           let data = try? JSONEncoder().encode(readBy),
           let jsonStr = String(data: data, encoding: .utf8) {
            self.readByJSON = jsonStr
        } else {
            self.readByJSON = nil
        }
    }
}

// MARK: - CDNotification

@objc(CDNotification)
public class CDNotification: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var recipient: String?
    @NSManaged public var type: String?
    @NSManaged public var entityType: String?
    @NSManaged public var entityId: String?
    @NSManaged public var message: String?
    @NSManaged public var readAt: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var conversationId: String?
    @NSManaged public var cachedAt: Date?
    
    // Embedded Actor (User)
    @NSManaged public var actorId: String?
    @NSManaged public var actorFullName: String?
    @NSManaged public var actorUsername: String?
    @NSManaged public var actorAvatarURL: String?
    
    func toNotification() -> AppNotification {
        let actor = User(
            id: actorId ?? "",
            fullName: actorFullName ?? "User",
            username: actorUsername ?? "user",
            avatarURL: actorAvatarURL
        )
        
        let notifType = NotificationType(rawValue: type ?? "message") ?? .message
        let metadata = conversationId != nil ? NotificationMetadata(conversationId: conversationId) : nil
        
        return AppNotification(
            id: id ?? UUID().uuidString,
            recipient: recipient ?? "",
            actor: actor,
            type: notifType,
            entityType: entityType,
            entityId: entityId,
            message: message ?? "",
            metadata: metadata,
            readAt: readAt,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    func update(from notification: AppNotification) {
        self.id = notification.id
        self.recipient = notification.recipient
        self.type = notification.type.rawValue
        self.entityType = notification.entityType
        self.entityId = notification.entityId
        self.message = notification.message
        self.readAt = notification.readAt
        self.createdAt = notification.createdAt
        self.updatedAt = notification.updatedAt
        self.conversationId = notification.metadata?.conversationId
        self.cachedAt = Date()
        
        self.actorId = notification.actor.id
        self.actorFullName = notification.actor.fullName
        self.actorUsername = notification.actor.username
        self.actorAvatarURL = notification.actor.avatarURL
    }
}
