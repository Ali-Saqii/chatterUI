//
//  AppState.swift
//  chatter
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoadingUser: Bool = false
    @Published var banner: BannerData? = nil
    @Published var unreadNotificationCount: Int = 0
    @AppStorage("appAppearanceSelection") var appearanceSelection: String = "system"
    
    var preferredColorScheme: ColorScheme? {
        switch appearanceSelection {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var bannerDismissTask: Task<Void, Never>?
    
    init() {
        // Pre-load cached user from Core Data for instant offline profile display
        if let cachedUser = CoreDataManager.shared.loadCachedCurrentUser() {
            self.currentUser = cachedUser
        }
        
        // Check initial auth state & connect socket if already authenticated
        if let token = KeychainManager.shared.getToken(), !token.isEmpty {
            self.isAuthenticated = true
            Task {
                await fetchCurrentUser()
            }
            // Start socket connection with existing token
            SocketService.shared.connect(token: token)
            Task {
                await fetchUnreadNotificationCount()
            }
        }
        
        // Listen to session expiration notifications
        NotificationCenter.default.publisher(for: AuthInterceptor.sessionDidExpireNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSessionExpired()
            }
            .store(in: &cancellables)
        
        // Reconnect socket when app returns to foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isAuthenticated else { return }
                if !SocketService.shared.isConnected,
                   let token = KeychainManager.shared.getToken() {
                    SocketService.shared.connect(token: token)
                }
                Task { [weak self] in
                    await self?.fetchUnreadNotificationCount()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to socket events for real-time badge updates
        subscribeToSocketEvents()
    }
    
    func setAuthenticated(token: String, user: User?) {
        _ = KeychainManager.shared.saveToken(token)
        self.currentUser = user
        self.isAuthenticated = true
        if let user = user {
            CoreDataManager.shared.saveCurrentUser(user)
        }
        showBanner("Welcome back, @\(user?.username ?? "user")!", type: .success)
        
        // Connect socket with the new token
        SocketService.shared.connect(token: token)
        NotificationManager.shared.requestAuthorization()
        Task {
            await fetchUnreadNotificationCount()
        }
        
        if user == nil {
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    func fetchCurrentUser() async {
        guard isAuthenticated else { return }
        isLoadingUser = true
        defer { isLoadingUser = false }
        
        do {
            let user: User = try await APIClient.shared.request(.getMyProfile)
            self.currentUser = user
            CoreDataManager.shared.saveCurrentUser(user)
        } catch {
            // 401 is handled by AuthInterceptor → NotificationCenter → handleSessionExpired()
            // In offline mode, fallback to cached user
            if currentUser == nil {
                self.currentUser = CoreDataManager.shared.loadCachedCurrentUser()
            }
        }
    }
    
    func updateCurrentUser(_ updatedUser: User) {
        self.currentUser = updatedUser
        CoreDataManager.shared.saveCurrentUser(updatedUser)
    }
    
    func logout() {
        SocketService.shared.disconnect()
        _ = KeychainManager.shared.deleteToken()
        CoreDataManager.shared.clearAllCache()
        self.currentUser = nil
        self.isAuthenticated = false
        self.unreadNotificationCount = 0
        showBanner("Logged out successfully.", type: .info)
    }
    
    private func handleSessionExpired() {
        SocketService.shared.disconnect()
        _ = KeychainManager.shared.deleteToken()
        self.currentUser = nil
        self.isAuthenticated = false
        self.unreadNotificationCount = 0
        showBanner("Session expired. Please log in again.", type: .error)
    }
    
    func showBanner(_ message: String, type: BannerType = .info) {
        bannerDismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.banner = BannerData(message: message, type: type)
        }
        
        bannerDismissTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.banner = nil
                }
            }
        }
    }
    
    func dismissBanner() {
        bannerDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            self.banner = nil
        }
    }
    
    // MARK: - Notification Badge
    
    func fetchUnreadNotificationCount() async {
        do {
            let data: UnreadCountData = try await APIClient.shared.request(.getUnreadNotificationCount)
            self.unreadNotificationCount = data.unreadCount
        } catch {
            // Silently fail — badge is non-critical
        }
    }
    
    private func subscribeToSocketEvents() {
        SocketService.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .newNotification(let notification):
                    self.unreadNotificationCount += 1
                    CoreDataManager.shared.saveNotification(notification)
                    NotificationManager.shared.scheduleLocalNotification(from: notification)
                case .notificationRead:
                    if self.unreadNotificationCount > 0 {
                        self.unreadNotificationCount -= 1
                    }
                case .allNotificationsRead:
                    self.unreadNotificationCount = 0
                case .connected:
                    Task { [weak self] in
                        await self?.fetchUnreadNotificationCount()
                    }
                case .disconnected:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
