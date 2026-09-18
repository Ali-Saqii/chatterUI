//
//  ChatViewModel.swift
//  chatter
//

import SwiftUI
import Combine

struct ChatMessage: Identifiable, Equatable, Hashable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
    let isFromMe: Bool
}

struct ChatConversation: Identifiable, Equatable, Hashable {
    let id: String
    let participant: User
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var messages: [ChatMessage]
}

@MainActor
final class ChatViewModel: ObservableObject {}
