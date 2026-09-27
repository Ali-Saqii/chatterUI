//
//  NotificationRouter.swift
//  chatter
//

import SwiftUI
import Combine

@MainActor
final class NotificationRouter: ObservableObject {
    static let shared = NotificationRouter()
    
    @Published var targetPost: Post? = nil
    @Published var targetConversation: Conversation? = nil
    @Published var targetProfileUsername: String? = nil
    @Published var shouldOpenNotificationsList: Bool = false
    @Published var selectedTab: TabSelection? = nil
    
    private init() {}
    
    /// Route from an AppNotification object (e.g. tapped inside the app or from list)
    func route(from notification: AppNotification) {
        switch notification.type {
        case .like, .comment:
            if let postId = notification.entityId, !postId.isEmpty {
                routeToPost(postId: postId, fallbackAuthor: notification.actor)
            } else {
                shouldOpenNotificationsList = true
            }
            
        case .message:
            let convId = notification.metadata?.conversationId ?? notification.entityId ?? ""
            if !convId.isEmpty {
                routeToConversation(conversationId: convId, actor: notification.actor)
            } else {
                selectedTab = .chat
            }
            
        case .friendRequest, .friendRequestAccepted:
            routeToProfile(username: notification.actor.username)
        }
    }
    
    /// Route from remote/local notification payload dictionary (when tapped from iOS lock screen or notification banner)
    func routeFromUserInfo(_ userInfo: [AnyHashable: Any]) {
        let typeStr = (userInfo["type"] as? String)?.lowercased() ?? ""
        let entityType = (userInfo["entityType"] as? String)?.lowercased() ?? ""
        let entityId = userInfo["entityId"] as? String ?? ""
        let conversationId = userInfo["conversationId"] as? String ?? ""
        let actorUsername = userInfo["actorUsername"] as? String ?? userInfo["username"] as? String ?? ""
        let actorName = userInfo["actorName"] as? String ?? actorUsername
        let actorAvatar = userInfo["actorAvatar"] as? String
        let actorId = userInfo["actorId"] as? String ?? UUID().uuidString
        
        let actorUser = User(
            id: actorId,
            fullName: actorName.isEmpty ? "User" : actorName,
            username: actorUsername.isEmpty ? "user" : actorUsername,
            email: "",
            avatarURL: actorAvatar
        )
        
        if typeStr == "message" || entityType == "conversation" || !conversationId.isEmpty {
            let targetConvId = !conversationId.isEmpty ? conversationId : entityId
            if !targetConvId.isEmpty {
                routeToConversation(conversationId: targetConvId, actor: actorUser)
            } else {
                selectedTab = .chat
            }
        } else if typeStr == "like" || typeStr == "comment" || entityType == "post" {
            if !entityId.isEmpty {
                routeToPost(postId: entityId, fallbackAuthor: actorUser)
            } else {
                shouldOpenNotificationsList = true
            }
        } else if typeStr == "friend_request" || typeStr == "friend_request_accepted" || entityType == "user" {
            if !actorUsername.isEmpty {
                routeToProfile(username: actorUsername)
            } else {
                selectedTab = .people
            }
        } else {
            shouldOpenNotificationsList = true
        }
    }
    
    func routeToPost(postId: String, fallbackAuthor: User) {
        // 1. Try to find in Core Data cached posts
        if let cached = CoreDataManager.shared.loadCachedPosts().first(where: { $0.id == postId }) {
            self.targetPost = cached
            return
        }
        
        // 2. Fallback placeholder post for immediate presentation while comments load
        let placeholder = Post(
            id: postId,
            author: fallbackAuthor,
            text: nil,
            likesCount: 0,
            commentsCount: 0
        )
        self.targetPost = placeholder
    }
    
    func routeToConversation(conversationId: String, actor: User) {
        // 1. Try to find in Core Data cached conversations
        if let cached = CoreDataManager.shared.loadCachedConversations().first(where: { $0.id == conversationId }) {
            self.targetConversation = cached
            return
        }
        
        // 2. Fallback conversation for immediate presentation
        let conv = Conversation(
            id: conversationId,
            participants: [
                ConversationParticipant(
                    id: actor.id,
                    username: actor.username,
                    email: actor.email,
                    avatarURL: actor.avatarURL
                )
            ]
        )
        self.targetConversation = conv
    }
    
    func routeToProfile(username: String) {
        guard !username.isEmpty else { return }
        self.targetProfileUsername = username
    }
}
