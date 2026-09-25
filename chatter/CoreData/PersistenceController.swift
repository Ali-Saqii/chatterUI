//
//  PersistenceController.swift
//  chatter
//

import Foundation
import CoreData

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()
    
    // In-memory instance for Previews & Unit Tests
    static let preview: PersistenceController = {
        PersistenceController(inMemory: true)
    }()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        let model = PersistenceController.createManagedObjectModel()
        container = NSPersistentContainer(name: "ChatterData", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let description = container.persistentStoreDescriptions.first {
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("❌ [PersistenceController] Failed to load Core Data store: \(error), \(error.userInfo)")
            } else {
                print("✅ [PersistenceController] Core Data store ready: \(description.url?.lastPathComponent ?? "in-memory")")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Programmatic Schema Definition
    
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Helper to construct attribute descriptions
        func makeAttr(
            name: String,
            type: NSAttributeType,
            isOptional: Bool = true,
            defaultValue: Any? = nil
        ) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = isOptional
            if let defaultValue = defaultValue {
                attr.defaultValue = defaultValue
            }
            return attr
        }
        
        // 1. CDUser Entity
        let userEntity = NSEntityDescription()
        userEntity.name = "CDUser"
        userEntity.managedObjectClassName = NSStringFromClass(CDUser.self)
        userEntity.properties = [
            makeAttr(name: "id", type: .stringAttributeType),
            makeAttr(name: "fullName", type: .stringAttributeType),
            makeAttr(name: "username", type: .stringAttributeType),
            makeAttr(name: "email", type: .stringAttributeType),
            makeAttr(name: "bio", type: .stringAttributeType),
            makeAttr(name: "avatarURL", type: .stringAttributeType),
            makeAttr(name: "postsCount", type: .integer32AttributeType, defaultValue: 0),
            makeAttr(name: "friendsCount", type: .integer32AttributeType, defaultValue: 0),
            makeAttr(name: "createdAt", type: .dateAttributeType),
            makeAttr(name: "isCurrentUser", type: .booleanAttributeType, defaultValue: false),
            makeAttr(name: "isFriend", type: .booleanAttributeType, defaultValue: false),
            makeAttr(name: "cachedAt", type: .dateAttributeType)
        ]
        
        // 2. CDPost Entity
        let postEntity = NSEntityDescription()
        postEntity.name = "CDPost"
        postEntity.managedObjectClassName = NSStringFromClass(CDPost.self)
        postEntity.properties = [
            makeAttr(name: "id", type: .stringAttributeType),
            makeAttr(name: "text", type: .stringAttributeType),
            makeAttr(name: "mediaURL", type: .stringAttributeType),
            makeAttr(name: "mediaPublicId", type: .stringAttributeType),
            makeAttr(name: "mediaType", type: .stringAttributeType, defaultValue: "none"),
            makeAttr(name: "likesCount", type: .integer32AttributeType, defaultValue: 0),
            makeAttr(name: "commentsCount", type: .integer32AttributeType, defaultValue: 0),
            makeAttr(name: "createdAt", type: .dateAttributeType),
            makeAttr(name: "isLikedByMe", type: .booleanAttributeType, defaultValue: false),
            makeAttr(name: "cachedAt", type: .dateAttributeType),
            // Embedded Author
            makeAttr(name: "authorId", type: .stringAttributeType),
            makeAttr(name: "authorFullName", type: .stringAttributeType),
            makeAttr(name: "authorUsername", type: .stringAttributeType),
            makeAttr(name: "authorEmail", type: .stringAttributeType),
            makeAttr(name: "authorBio", type: .stringAttributeType),
            makeAttr(name: "authorAvatarURL", type: .stringAttributeType),
            makeAttr(name: "authorPostsCount", type: .integer32AttributeType, defaultValue: 0),
            makeAttr(name: "authorFriendsCount", type: .integer32AttributeType, defaultValue: 0)
        ]
        
        // 3. CDComment Entity
        let commentEntity = NSEntityDescription()
        commentEntity.name = "CDComment"
        commentEntity.managedObjectClassName = NSStringFromClass(CDComment.self)
        commentEntity.properties = [
            makeAttr(name: "id", type: .stringAttributeType),
            makeAttr(name: "postId", type: .stringAttributeType),
            makeAttr(name: "text", type: .stringAttributeType),
            makeAttr(name: "createdAt", type: .dateAttributeType),
            makeAttr(name: "cachedAt", type: .dateAttributeType),
            makeAttr(name: "authorId", type: .stringAttributeType),
            makeAttr(name: "authorFullName", type: .stringAttributeType),
            makeAttr(name: "authorUsername", type: .stringAttributeType),
            makeAttr(name: "authorAvatarURL", type: .stringAttributeType)
        ]
        
        // 4. CDConversation Entity
        let conversationEntity = NSEntityDescription()
        conversationEntity.name = "CDConversation"
        conversationEntity.managedObjectClassName = NSStringFromClass(CDConversation.self)
        conversationEntity.properties = [
            makeAttr(name: "id", type: .stringAttributeType),
            makeAttr(name: "isGroup", type: .booleanAttributeType, defaultValue: false),
            makeAttr(name: "groupName", type: .stringAttributeType),
            makeAttr(name: "groupAdmin", type: .stringAttributeType),
            makeAttr(name: "lastMessage", type: .stringAttributeType),
            makeAttr(name: "createdAt", type: .dateAttributeType),
            makeAttr(name: "updatedAt", type: .dateAttributeType),
            makeAttr(name: "cachedAt", type: .dateAttributeType),
            makeAttr(name: "participantsJSON", type: .stringAttributeType)
        ]
        
        // 5. CDMessage Entity
        let messageEntity = NSEntityDescription()
        messageEntity.name = "CDMessage"
        messageEntity.managedObjectClassName = NSStringFromClass(CDMessage.self)
        messageEntity.properties = [
            makeAttr(name: "id", type: .stringAttributeType),
            makeAttr(name: "conversationId", type: .stringAttributeType),
            makeAttr(name: "senderId", type: .stringAttributeType),
            makeAttr(name: "senderUsername", type: .stringAttributeType),
            makeAttr(name: "senderAvatarURL", type: .stringAttributeType),
            makeAttr(name: "text", type: .stringAttributeType),
            makeAttr(name: "mediaUrl", type: .stringAttributeType),
            makeAttr(name: "readByJSON", type: .stringAttributeType),
            makeAttr(name: "createdAt", type: .dateAttributeType),
            makeAttr(name: "updatedAt", type: .dateAttributeType),
            makeAttr(name: "cachedAt", type: .dateAttributeType)
        ]
        
        // 6. CDNotification Entity
        let notificationEntity = NSEntityDescription()
        notificationEntity.name = "CDNotification"
        notificationEntity.managedObjectClassName = NSStringFromClass(CDNotification.self)
        notificationEntity.properties = [
            makeAttr(name: "id", type: .stringAttributeType),
            makeAttr(name: "recipient", type: .stringAttributeType),
            makeAttr(name: "type", type: .stringAttributeType),
            makeAttr(name: "entityType", type: .stringAttributeType),
            makeAttr(name: "entityId", type: .stringAttributeType),
            makeAttr(name: "message", type: .stringAttributeType),
            makeAttr(name: "readAt", type: .dateAttributeType),
            makeAttr(name: "createdAt", type: .dateAttributeType),
            makeAttr(name: "updatedAt", type: .dateAttributeType),
            makeAttr(name: "conversationId", type: .stringAttributeType),
            makeAttr(name: "cachedAt", type: .dateAttributeType),
            makeAttr(name: "actorId", type: .stringAttributeType),
            makeAttr(name: "actorFullName", type: .stringAttributeType),
            makeAttr(name: "actorUsername", type: .stringAttributeType),
            makeAttr(name: "actorAvatarURL", type: .stringAttributeType)
        ]
        
        model.entities = [
            userEntity,
            postEntity,
            commentEntity,
            conversationEntity,
            messageEntity,
            notificationEntity
        ]
        
        return model
    }
}
