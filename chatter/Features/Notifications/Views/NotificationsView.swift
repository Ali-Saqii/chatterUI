//
//  NotificationsView.swift
//  chatter
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedPost: Post? = nil
    @State private var selectedConversation: Conversation? = nil
    @State private var selectedProfileUsername: String? = nil
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingView()
                    .padding(.top, 80)
            } else if viewModel.notifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "No Notifications",
                    description: "You're all caught up! New activity will appear here."
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                            handleNotificationTap(notification)
                        }
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(current: notification)
                            }
                        }
                        
                        if notification.id != viewModel.notifications.last?.id {
                            Divider()
                                .padding(.leading, 74)
                        }
                    }
                    
                    // Loading more indicator
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 16)
                    }
                }
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.unreadCount > 0 {
                    Button {
                        Task { await viewModel.markAllAsRead() }
                    } label: {
                        Text("Read All")
                            .font(.chatterSubheadline)
                            .foregroundColor(.chatterPrimary)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.fetchNotifications(isRefresh: true)
            appState.unreadNotificationCount = viewModel.unreadCount
        }
        .task {
            if viewModel.notifications.isEmpty {
                await viewModel.fetchNotifications()
                appState.unreadNotificationCount = viewModel.unreadCount
            }
        }
        .onChange(of: viewModel.unreadCount) { _, newValue in
            appState.unreadNotificationCount = newValue
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedPost != nil },
            set: { if !$0 { selectedPost = nil } }
        )) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedConversation != nil },
            set: { if !$0 { selectedConversation = nil } }
        )) {
            if let conv = selectedConversation {
                ChatDetailView(conversation: conv)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedProfileUsername != nil },
            set: { if !$0 { selectedProfileUsername = nil } }
        )) {
            if let username = selectedProfileUsername {
                ProfileView(username: username)
            }
        }
    }
    
    // MARK: - Navigation Handler
    private func handleNotificationTap(_ notification: AppNotification) {
        switch notification.type {
        case .like, .comment:
            if let postId = notification.entityId, !postId.isEmpty {
                if let cached = CoreDataManager.shared.loadCachedPosts().first(where: { $0.id == postId }) {
                    selectedPost = cached
                } else {
                    selectedPost = Post(
                        id: postId,
                        author: notification.actor,
                        text: nil,
                        likesCount: 0,
                        commentsCount: 0
                    )
                }
            }
            
        case .message:
            let convId = notification.metadata?.conversationId ?? notification.entityId ?? ""
            if !convId.isEmpty {
                if let cached = CoreDataManager.shared.loadCachedConversations().first(where: { $0.id == convId }) {
                    selectedConversation = cached
                } else {
                    selectedConversation = Conversation(
                        id: convId,
                        participants: [
                            ConversationParticipant(
                                id: notification.actor.id,
                                username: notification.actor.username,
                                email: notification.actor.email,
                                avatarURL: notification.actor.avatarURL
                            )
                        ]
                    )
                }
            }
            
        case .friendRequest, .friendRequestAccepted:
            selectedProfileUsername = notification.actor.username
        }
    }
}

#Preview("Notifications") {
    NavigationStack {
        NotificationsView()
    }
    .environmentObject(AppState())
}
