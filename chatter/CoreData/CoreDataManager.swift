//
//  CoreDataManager.swift
//  chatter
//

import Foundation
import CoreData

final class CoreDataManager: @unchecked Sendable {
    static let shared = CoreDataManager()
    
    private let persistence: PersistenceController
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }
    
    // MARK: - Posts Persistence
    
    func savePosts(_ posts: [Post], clearExisting: Bool = false) {
        guard !posts.isEmpty || clearExisting else { return }
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                if clearExisting {
                    let fetchRequest: NSFetchRequest<CDPost> = NSFetchRequest(entityName: "CDPost")
                    let existing = try context.fetch(fetchRequest)
                    for post in existing {
                        context.delete(post)
                    }
                }
                
                for post in posts {
                    let fetch: NSFetchRequest<CDPost> = NSFetchRequest(entityName: "CDPost")
                    fetch.predicate = NSPredicate(format: "id == %@", post.id)
                    let match = try context.fetch(fetch).first
                    let cdPost = match ?? CDPost(context: context)
                    cdPost.update(from: post)
                }
                
                if context.hasChanges {
                    try context.save()
                    print("💾 [CoreDataManager] Successfully cached \(posts.count) posts")
                }
            } catch {
                print("❌ [CoreDataManager] Error saving posts: \(error)")
            }
        }
    }
    
    func savePost(_ post: Post) {
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                let fetch: NSFetchRequest<CDPost> = NSFetchRequest(entityName: "CDPost")
                fetch.predicate = NSPredicate(format: "id == %@", post.id)
                let match = try context.fetch(fetch).first
                let cdPost = match ?? CDPost(context: context)
                cdPost.update(from: post)
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                print("❌ [CoreDataManager] Error saving single post: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedPosts() -> [Post] {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDPost> = NSFetchRequest(entityName: "CDPost")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            let results = try context.fetch(request)
            return results.map { $0.toPost() }
        } catch {
            print("❌ [CoreDataManager] Failed to load cached posts: \(error)")
            return []
        }
    }
    
    func updatePostLike(postId: String, isLikedByMe: Bool, likesCount: Int) {
        let context = persistence.newBackgroundContext()
        context.perform {
            let fetch: NSFetchRequest<CDPost> = NSFetchRequest(entityName: "CDPost")
            fetch.predicate = NSPredicate(format: "id == %@", postId)
            if let cdPost = (try? context.fetch(fetch))?.first {
                cdPost.isLikedByMe = isLikedByMe
                cdPost.likesCount = Int32(likesCount)
                try? context.save()
            }
        }
    }
    
    func deleteCachedPost(postId: String) {
        let context = persistence.newBackgroundContext()
        context.perform {
            let fetch: NSFetchRequest<CDPost> = NSFetchRequest(entityName: "CDPost")
            fetch.predicate = NSPredicate(format: "id == %@", postId)
            if let cdPost = (try? context.fetch(fetch))?.first {
                context.delete(cdPost)
                try? context.save()
            }
        }
    }
    
    // MARK: - Comments Persistence
    
    func saveComments(_ comments: [Comment], for postId: String) {
        guard !comments.isEmpty else { return }
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                // Delete existing cached comments for this post
                let fetchRequest: NSFetchRequest<CDComment> = NSFetchRequest(entityName: "CDComment")
                fetchRequest.predicate = NSPredicate(format: "postId == %@", postId)
                let existing = try context.fetch(fetchRequest)
                for comment in existing {
                    context.delete(comment)
                }
                
                for comment in comments {
                    let cdComment = CDComment(context: context)
                    cdComment.update(from: comment)
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                print("❌ [CoreDataManager] Error saving comments: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedComments(for postId: String) -> [Comment] {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDComment> = NSFetchRequest(entityName: "CDComment")
        request.predicate = NSPredicate(format: "postId == %@", postId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let results = try context.fetch(request)
            return results.map { $0.toComment() }
        } catch {
            print("❌ [CoreDataManager] Failed to load cached comments: \(error)")
            return []
        }
    }
    
    // MARK: - Conversations Persistence
    
    func saveConversations(_ conversations: [Conversation]) {
        guard !conversations.isEmpty else { return }
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                for conv in conversations {
                    let fetch: NSFetchRequest<CDConversation> = NSFetchRequest(entityName: "CDConversation")
                    fetch.predicate = NSPredicate(format: "id == %@", conv.id)
                    let match = try context.fetch(fetch).first
                    let cdConv = match ?? CDConversation(context: context)
                    cdConv.update(from: conv)
                }
                
                if context.hasChanges {
                    try context.save()
                    print("💾 [CoreDataManager] Successfully cached \(conversations.count) conversations")
                }
            } catch {
                print("❌ [CoreDataManager] Error saving conversations: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedConversations() -> [Conversation] {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDConversation> = NSFetchRequest(entityName: "CDConversation")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        do {
            let results = try context.fetch(request)
            return results.map { $0.toConversation() }
        } catch {
            print("❌ [CoreDataManager] Failed to load cached conversations: \(error)")
            return []
        }
    }
    
    // MARK: - Messages Persistence
    
    func saveMessages(_ messages: [Message], conversationId: String) {
        guard !messages.isEmpty else { return }
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                for msg in messages {
                    let fetch: NSFetchRequest<CDMessage> = NSFetchRequest(entityName: "CDMessage")
                    fetch.predicate = NSPredicate(format: "id == %@", msg.id)
                    let match = try context.fetch(fetch).first
                    let cdMsg = match ?? CDMessage(context: context)
                    cdMsg.update(from: msg)
                }
                
                if context.hasChanges {
                    try context.save()
                    print("💾 [CoreDataManager] Cached \(messages.count) messages for conversation \(conversationId)")
                }
            } catch {
                print("❌ [CoreDataManager] Error saving messages: \(error)")
            }
        }
    }
    
    func saveMessage(_ message: Message) {
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                let fetch: NSFetchRequest<CDMessage> = NSFetchRequest(entityName: "CDMessage")
                fetch.predicate = NSPredicate(format: "id == %@", message.id)
                let match = try context.fetch(fetch).first
                let cdMsg = match ?? CDMessage(context: context)
                cdMsg.update(from: message)
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                print("❌ [CoreDataManager] Error saving single message: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedMessages(conversationId: String) -> [Message] {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDMessage> = NSFetchRequest(entityName: "CDMessage")
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let results = try context.fetch(request)
            return results.map { $0.toMessage() }
        } catch {
            print("❌ [CoreDataManager] Failed to load cached messages: \(error)")
            return []
        }
    }
    
    // MARK: - Notifications Persistence
    
    func saveNotifications(_ notifications: [AppNotification]) {
        guard !notifications.isEmpty else { return }
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                for notif in notifications {
                    let fetch: NSFetchRequest<CDNotification> = NSFetchRequest(entityName: "CDNotification")
                    fetch.predicate = NSPredicate(format: "id == %@", notif.id)
                    let match = try context.fetch(fetch).first
                    let cdNotif = match ?? CDNotification(context: context)
                    cdNotif.update(from: notif)
                }
                
                if context.hasChanges {
                    try context.save()
                    print("💾 [CoreDataManager] Cached \(notifications.count) notifications")
                }
            } catch {
                print("❌ [CoreDataManager] Error saving notifications: \(error)")
            }
        }
    }
    
    func saveNotification(_ notification: AppNotification) {
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                let fetch: NSFetchRequest<CDNotification> = NSFetchRequest(entityName: "CDNotification")
                fetch.predicate = NSPredicate(format: "id == %@", notification.id)
                let match = try context.fetch(fetch).first
                let cdNotif = match ?? CDNotification(context: context)
                cdNotif.update(from: notification)
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                print("❌ [CoreDataManager] Error saving single notification: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedNotifications() -> [AppNotification] {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDNotification> = NSFetchRequest(entityName: "CDNotification")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            let results = try context.fetch(request)
            return results.map { $0.toNotification() }
        } catch {
            print("❌ [CoreDataManager] Failed to load cached notifications: \(error)")
            return []
        }
    }
    
    func markCachedNotificationRead(id: String, readAt: Date) {
        let context = persistence.newBackgroundContext()
        context.perform {
            let fetch: NSFetchRequest<CDNotification> = NSFetchRequest(entityName: "CDNotification")
            fetch.predicate = NSPredicate(format: "id == %@", id)
            if let cdNotif = (try? context.fetch(fetch))?.first {
                cdNotif.readAt = readAt
                try? context.save()
            }
        }
    }
    
    func markAllCachedNotificationsRead(readAt: Date = Date()) {
        let context = persistence.newBackgroundContext()
        context.perform {
            let fetch: NSFetchRequest<CDNotification> = NSFetchRequest(entityName: "CDNotification")
            fetch.predicate = NSPredicate(format: "readAt == nil")
            if let unreadList = try? context.fetch(fetch) {
                for item in unreadList {
                    item.readAt = readAt
                }
                try? context.save()
            }
        }
    }
    
    // MARK: - Current User & Friends Persistence
    
    func saveCurrentUser(_ user: User) {
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                // Clear any previous isCurrentUser flag
                let fetchPrevious: NSFetchRequest<CDUser> = NSFetchRequest(entityName: "CDUser")
                fetchPrevious.predicate = NSPredicate(format: "isCurrentUser == YES")
                let previous = try context.fetch(fetchPrevious)
                for u in previous {
                    u.isCurrentUser = false
                }
                
                // Fetch or create user
                let fetch: NSFetchRequest<CDUser> = NSFetchRequest(entityName: "CDUser")
                fetch.predicate = NSPredicate(format: "id == %@", user.id)
                let match = try context.fetch(fetch).first
                let cdUser = match ?? CDUser(context: context)
                cdUser.update(from: user, isCurrentUser: true)
                
                try context.save()
                print("💾 [CoreDataManager] Cached current user: @\(user.username)")
            } catch {
                print("❌ [CoreDataManager] Error saving current user: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedCurrentUser() -> User? {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDUser> = NSFetchRequest(entityName: "CDUser")
        request.predicate = NSPredicate(format: "isCurrentUser == YES")
        do {
            let match = try context.fetch(request).first
            return match?.toUser()
        } catch {
            print("❌ [CoreDataManager] Failed to load cached current user: \(error)")
            return nil
        }
    }
    
    func saveFriends(_ friends: [User]) {
        guard !friends.isEmpty else { return }
        let context = persistence.newBackgroundContext()
        context.perform {
            do {
                for friend in friends {
                    let fetch: NSFetchRequest<CDUser> = NSFetchRequest(entityName: "CDUser")
                    fetch.predicate = NSPredicate(format: "id == %@", friend.id)
                    let match = try context.fetch(fetch).first
                    let cdUser = match ?? CDUser(context: context)
                    cdUser.update(from: friend, isFriend: true)
                }
                
                if context.hasChanges {
                    try context.save()
                    print("💾 [CoreDataManager] Cached \(friends.count) friends")
                }
            } catch {
                print("❌ [CoreDataManager] Error saving friends: \(error)")
            }
        }
    }
    
    @MainActor
    func loadCachedFriends() -> [User] {
        let context = persistence.viewContext
        let request: NSFetchRequest<CDUser> = NSFetchRequest(entityName: "CDUser")
        request.predicate = NSPredicate(format: "isFriend == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "fullName", ascending: true)]
        do {
            let results = try context.fetch(request)
            return results.map { $0.toUser() }
        } catch {
            print("❌ [CoreDataManager] Failed to load cached friends: \(error)")
            return []
        }
    }
    
    // MARK: - Clear All Cache (Logout)
    
    func clearAllCache() {
        let context = persistence.newBackgroundContext()
        context.perform {
            let entityNames = ["CDUser", "CDPost", "CDComment", "CDConversation", "CDMessage", "CDNotification"]
            for name in entityNames {
                let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: name)
                if let objects = try? context.fetch(fetchRequest) {
                    for obj in objects {
                        context.delete(obj)
                    }
                }
            }
            try? context.save()
            print("🧹 [CoreDataManager] All Core Data cache cleared successfully")
        }
    }
}
