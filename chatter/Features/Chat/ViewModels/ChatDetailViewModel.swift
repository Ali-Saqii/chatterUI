//
//  ChatDetailViewModel.swift
//  chatter
//

import SwiftUI
import Combine

@MainActor
final class ChatDetailViewModel: ObservableObject {
    @Published var conversation: Conversation
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var messageText: String = ""
    @Published var errorMessage: String? = nil
    
    private var timerTask: Task<Void, Never>?
    
    init(conversation: Conversation) {
        self.conversation = conversation
        let cached = CoreDataManager.shared.loadCachedMessages(conversationId: conversation.id)
        if !cached.isEmpty {
            self.messages = cached
        }
    }
    
    deinit {
        timerTask?.cancel()
    }
    
    func startPolling(currentUserId: String?) {
        stopPolling()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // Poll every 3s
                guard let self = self else { break }
                await self.fetchMessages(silent: true, currentUserId: currentUserId)
            }
        }
    }
    
    func stopPolling() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    func fetchMessages(silent: Bool = false, currentUserId: String? = nil) async {
        if !silent && messages.isEmpty {
            isLoading = true
        }
        
        do {
            let data: MessagesData = try await APIClient.shared.request(.getMessages(conversationId: conversation.id, page: 1, limit: 100))
            // Messages from API are newest first; reverse them for chronological rendering
            let fetched = Array(data.messages.reversed())
            
            // Persist messages to Core Data
            CoreDataManager.shared.saveMessages(fetched, conversationId: conversation.id)
            
            // Only update if changes occurred to prevent unnecessary redraws
            if fetched != self.messages {
                self.messages = fetched
                
                // Mark unread messages as read for current user
                if let currentUserId = currentUserId {
                    for msg in fetched where !(msg.readBy?.contains(currentUserId) ?? false) && msg.sender.id != currentUserId {
                        Task {
                            let _: Message = (try? await APIClient.shared.request(.markMessageRead(messageId: msg.id))) ?? msg
                        }
                    }
                }
            }
        } catch {
            if self.messages.isEmpty {
                let cached = CoreDataManager.shared.loadCachedMessages(conversationId: conversation.id)
                if !cached.isEmpty {
                    self.messages = cached
                }
            }
            if !silent {
                print("❌ [ChatDetailViewModel] Error fetching messages: \(error)")
                if !NetworkMonitor.shared.isConnected {
                    self.errorMessage = "Offline mode — displaying cached messages."
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        isLoading = false
    }
    
    func sendMessage(mediaUrl: String? = nil) async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || mediaUrl != nil else { return }
        
        let textToSend = trimmed.isEmpty ? nil : trimmed
        messageText = ""
        isSending = true
        
        let request = SendMessageRequest(text: textToSend, mediaUrl: mediaUrl)
        
        do {
            let newMsg: Message = try await APIClient.shared.request(.sendMessage(conversationId: conversation.id), body: request)
            if !self.messages.contains(where: { $0.id == newMsg.id }) {
                self.messages.append(newMsg)
            }
            // Save newly sent message to Core Data cache
            CoreDataManager.shared.saveMessage(newMsg)
        } catch {
            print("❌ [ChatDetailViewModel] Error sending message: \(error)")
            self.errorMessage = error.localizedDescription
            // Restore text if send failed
            if let text = textToSend {
                self.messageText = text
            }
        }
        
        isSending = false
    }
    
    func deleteMessage(_ message: Message) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deleteMessage(messageId: message.id))
            self.messages.removeAll { $0.id == message.id }
        } catch {
            print("❌ [ChatDetailViewModel] Error deleting message: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
}
