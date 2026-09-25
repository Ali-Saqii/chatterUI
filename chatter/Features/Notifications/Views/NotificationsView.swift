//
//  NotificationsView.swift
//  chatter
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject private var appState: AppState
    
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
    }
}

#Preview("Notifications") {
    NavigationStack {
        NotificationsView()
    }
    .environmentObject(AppState())
}
