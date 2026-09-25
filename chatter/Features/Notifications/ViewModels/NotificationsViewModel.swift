//
//  NotificationsViewModel.swift
//  chatter
//

import SwiftUI
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    
    private var currentPage = 1
    private let limit = 20
    private var canLoadMore = true
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let cached = CoreDataManager.shared.loadCachedNotifications()
        if !cached.isEmpty {
            self.notifications = cached
            self.unreadCount = cached.filter { $0.readAt == nil }.count
        }
        subscribeToSocketEvents()
    }
    
    // MARK: - Socket.IO Real-Time Updates
    
    private func subscribeToSocketEvents() {
        SocketService.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                self.handleSocketEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleSocketEvent(_ event: SocketEvent) {
        switch event {
        case .newNotification(let notification):
            withAnimation(.easeOut(duration: 0.25)) {
                // Insert at the top, avoid duplicates
                if !notifications.contains(where: { $0.id == notification.id }) {
                    notifications.insert(notification, at: 0)
                }
                unreadCount += 1
            }
            CoreDataManager.shared.saveNotification(notification)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
        case .notificationRead(let notificationId, let readAt):
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                withAnimation {
                    notifications[index].readAt = readAt
                }
                if unreadCount > 0 { unreadCount -= 1 }
            }
            CoreDataManager.shared.markCachedNotificationRead(id: notificationId, readAt: readAt)
            
        case .allNotificationsRead:
            withAnimation {
                for i in notifications.indices {
                    if notifications[i].readAt == nil {
                        notifications[i].readAt = Date()
                    }
                }
                unreadCount = 0
            }
            CoreDataManager.shared.markAllCachedNotificationsRead()
            
        case .connected, .disconnected:
            break
        }
    }
    
    // MARK: - Fetch Notifications (REST)
    
    func fetchNotifications(isRefresh: Bool = false) async {
        if isRefresh {
            isRefreshing = true
            currentPage = 1
            canLoadMore = true
        } else if notifications.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        defer {
            isLoading = false
            isRefreshing = false
        }
        
        do {
            let data: NotificationListData = try await APIClient.shared.request(
                .getNotifications(page: currentPage, limit: limit)
            )
            
            if isRefresh || currentPage == 1 {
                self.notifications = data.notifications
            } else {
                let existingIds = Set(notifications.map { $0.id })
                let newOnes = data.notifications.filter { !existingIds.contains($0.id) }
                self.notifications.append(contentsOf: newOnes)
            }
            
            // Persist to Core Data
            CoreDataManager.shared.saveNotifications(data.notifications)
            
            self.unreadCount = data.unreadCount
            self.canLoadMore = data.pagination.page < data.pagination.totalPages
            if canLoadMore { currentPage += 1 }
        } catch {
            if self.notifications.isEmpty {
                let cached = CoreDataManager.shared.loadCachedNotifications()
                if !cached.isEmpty {
                    self.notifications = cached
                    self.unreadCount = cached.filter { $0.readAt == nil }.count
                }
            }
            if !NetworkMonitor.shared.isConnected {
                errorMessage = "Offline mode — displaying cached notifications."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Unread Count
    
    func fetchUnreadCount() async {
        do {
            let data: UnreadCountData = try await APIClient.shared.request(.getUnreadNotificationCount)
            self.unreadCount = data.unreadCount
        } catch {
            // Silently fail — badge is not critical
        }
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(_ notification: AppNotification) async {
        guard notification.readAt == nil else { return }
        
        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].readAt = Date()
            if unreadCount > 0 { unreadCount -= 1 }
        }
        CoreDataManager.shared.markCachedNotificationRead(id: notification.id, readAt: Date())
        
        do {
            let _: AppNotification = try await APIClient.shared.request(
                .markNotificationRead(notificationId: notification.id)
            )
        } catch {
            // Revert on failure
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].readAt = nil
                unreadCount += 1
            }
        }
    }
    
    func markAllAsRead() async {
        guard unreadCount > 0 else { return }
        
        // Optimistic update
        let previousUnread = unreadCount
        withAnimation {
            for i in notifications.indices {
                if notifications[i].readAt == nil {
                    notifications[i].readAt = Date()
                }
            }
            unreadCount = 0
        }
        CoreDataManager.shared.markAllCachedNotificationsRead()
        
        do {
            let _: MarkAllReadData = try await APIClient.shared.request(.markAllNotificationsRead)
        } catch {
            // Revert on failure — refetch
            unreadCount = previousUnread
            await fetchNotifications(isRefresh: true)
        }
    }
    
    // MARK: - Infinite Scroll
    
    func loadMoreIfNeeded(current: AppNotification) async {
        guard canLoadMore, !isLoading, !isLoadingMore else { return }
        
        guard let index = notifications.firstIndex(where: { $0.id == current.id }),
              index >= notifications.count - 3 else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let data: NotificationListData = try await APIClient.shared.request(
                .getNotifications(page: currentPage, limit: limit)
            )
            
            let existingIds = Set(notifications.map { $0.id })
            let newOnes = data.notifications.filter { !existingIds.contains($0.id) }
            self.notifications.append(contentsOf: newOnes)
            
            self.canLoadMore = data.pagination.page < data.pagination.totalPages
            if canLoadMore { currentPage += 1 }
        } catch {
            // Silently handle pagination errors
        }
    }
}
