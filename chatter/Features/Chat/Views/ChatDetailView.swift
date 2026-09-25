//
//  ChatDetailView.swift
//  chatter
//

import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatDetailViewModel
    
    init(conversation: Conversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages Scroll View
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 20)
                        } else if viewModel.messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.chatterSubtext.opacity(0.4))
                                Text("No messages yet")
                                    .font(.chatterHeadline)
                                    .foregroundColor(.chatterText)
                                Text("Send a message to start the conversation.")
                                    .font(.chatterSubheadline)
                                    .foregroundColor(.chatterSubtext)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(viewModel.messages) { message in
                                messageRow(message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Message Input Bar
            HStack(spacing: 10) {
                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .font(.chatterBody)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.chatterInputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                            : Color.chatterGradient
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.chatterPrimary.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.chatterCardBackground.ignoresSafeArea(edges: .bottom))
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    if conversation.isGroup {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.chatterPrimary)
                    } else {
                        AvatarView(
                            urlString: conversation.displayAvatarURL(currentUserId: appState.currentUser?.id),
                            name: conversation.displayTitle(currentUserId: appState.currentUser?.id),
                            size: 28
                        )
                    }
                    
                    Text(conversation.displayTitle(currentUserId: appState.currentUser?.id))
                        .font(.chatterHeadline)
                        .foregroundColor(.chatterText)
                        .lineLimit(1)
                }
            }
        }
        .task {
            await viewModel.fetchMessages(currentUserId: appState.currentUser?.id)
            viewModel.startPolling(currentUserId: appState.currentUser?.id)
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
    
    @ViewBuilder
    private func messageRow(_ message: Message) -> some View {
        let isMe = message.isFromUser(userId: appState.currentUser?.id)
        
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 50) }
            
            if !isMe && conversation.isGroup {
                AvatarView(
                    urlString: message.sender.avatarURL,
                    name: message.sender.username ?? "User",
                    size: 28
                )
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe && conversation.isGroup, let username = message.sender.username {
                    Text("@\(username)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.chatterSubtext)
                        .padding(.horizontal, 4)
                }
                
                VStack(alignment: isMe ? .trailing : .leading, spacing: 6) {
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .font(.chatterBody)
                            .foregroundColor(isMe ? .white : .chatterText)
                    }
                    
                    if let mediaUrl = message.mediaUrl, let url = URL(string: mediaUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 240, maxHeight: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.chatterSubtext)
                                    .frame(width: 120, height: 120)
                            default:
                                ProgressView()
                                    .frame(width: 120, height: 120)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isMe
                    ? AnyShapeStyle(Color.chatterGradient)
                    : AnyShapeStyle(Color.chatterCardBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                
                // Timestamp & status
                HStack(spacing: 4) {
                    Text(formatMessageTime(message.createdAt))
                        .font(.system(size: 10))
                        .foregroundColor(.chatterSubtext)
                    
                    if isMe {
                        let isRead = (message.readBy?.count ?? 0) > 1
                        Image(systemName: isRead ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isRead ? .chatterPrimary : .chatterSubtext)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isMe { Spacer(minLength: 50) }
        }
        .contextMenu {
            if isMe {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.deleteMessage(message)
                    }
                }) {
                    Label("Delete Message", systemImage: "trash")
                }
            }
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
