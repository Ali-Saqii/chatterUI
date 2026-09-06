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
    
    private var cancellables = Set<AnyCancellable>()
    private var bannerDismissTask: Task<Void, Never>?
    
    init() {
        // Check initial auth state
        if let token = KeychainManager.shared.getToken(), !token.isEmpty {
            self.isAuthenticated = true
            Task {
                await fetchCurrentUser()
            }
        }
        
        // Listen to session expiration notifications
        NotificationCenter.default.publisher(for: AuthInterceptor.sessionDidExpireNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSessionExpired()
            }
            .store(in: &cancellables)
    }
    
    func setAuthenticated(token: String, user: User?) {
        _ = KeychainManager.shared.saveToken(token)
        self.currentUser = user
        self.isAuthenticated = true
        showBanner("Welcome back, @\(user?.username ?? "user")!", type: .success)
        
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
        } catch {
            // If unauthorized, token is invalid
            if case APIError.unauthorized = error {
                handleSessionExpired()
            }
        }
    }
    
    func updateCurrentUser(_ updatedUser: User) {
        self.currentUser = updatedUser
    }
    
    func logout() {
        _ = KeychainManager.shared.deleteToken()
        self.currentUser = nil
        self.isAuthenticated = false
        showBanner("Logged out successfully.", type: .info)
    }
    
    private func handleSessionExpired() {
        _ = KeychainManager.shared.deleteToken()
        self.currentUser = nil
        self.isAuthenticated = false
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
}
