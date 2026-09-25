//
//  ChatListView.swift
//  chatter
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedConversation: Conversation? = nil
    @State private var searchQuery: String = ""
    
    var filteredConversations: [Conversation] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return viewModel.conversations
        }
        let currentUserId = appState.currentUser?.id
        return viewModel.conversations.filter { conv in
            conv.displayTitle(currentUserId: currentUserId)
                .localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    var body: some View {
        ZStack {
            Color.chatterBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                if !viewModel.conversations.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.chatterSubtext)
                        
                        TextField("Search chats...", text: $searchQuery)
                            .font(.chatterBody)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.chatterSubtext)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.chatterInputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    Spacer()
                    ProgressView("Loading chats...")
                    Spacer()
                } else if viewModel.conversations.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "No Conversations Yet",
                        description: "Start a conversation with a friend or create a group chat!",
                        buttonTitle: "Start New Chat"
                    ) {
                        viewModel.showNewChatSheet = true
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredConversations) { conversation in
                            Button(action: {
                                selectedConversation = conversation
                            }) {
                                conversationRow(conversation)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.leaveConversation(id: conversation.id)
                                    }
                                } label: {
                                    Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchConversations()
                    }
                }
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.showNewChatSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.chatterGradient)
                }
            }
        }
        .sheet(isPresented: $viewModel.showNewChatSheet) {
            NewChatSheetView(viewModel: viewModel) { conversation in
                selectedConversation = conversation
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedConversation != nil },
            set: { if !$0 { selectedConversation = nil } }
        )) {
            if let conversation = selectedConversation {
                ChatDetailView(conversation: conversation)
            }
        }
        .task {
            await viewModel.fetchConversations()
        }
    }
    
    @ViewBuilder
    private func conversationRow(_ conversation: Conversation) -> some View {
        let currentUserId = appState.currentUser?.id
        let title = conversation.displayTitle(currentUserId: currentUserId)
        let avatarURL = conversation.displayAvatarURL(currentUserId: currentUserId)
        
        HStack(spacing: 14) {
            if conversation.isGroup {
                ZStack {
                    Circle()
                        .fill(Color.chatterPrimary.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.chatterPrimary)
                }
            } else {
                AvatarView(
                    urlString: avatarURL,
                    name: title,
                    size: 50
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.chatterText)
                        .lineLimit(1)
                    
                    if conversation.isGroup {
                        Text("Group")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.chatterPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.chatterPrimary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Text(formatDate(conversation.updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(.chatterSubtext)
                }
                
                Text(conversation.lastMessage ?? "No messages yet")
                    .font(.system(size: 14))
                    .foregroundColor(.chatterSubtext)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
