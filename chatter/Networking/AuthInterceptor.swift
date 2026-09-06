//
//  AuthInterceptor.swift
//  chatter
//

import Foundation

final class AuthInterceptor {
    static let shared = AuthInterceptor()
    
    // Notification when session expires or 401 received
    static let sessionDidExpireNotification = Notification.Name("ChatterSessionDidExpireNotification")
    
    private init() {}
    
    func adapt(_ request: inout URLRequest, requiresAuth: Bool = true) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth, let token = KeychainManager.shared.getToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    func handleResponse(_ response: URLResponse?) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        if httpResponse.statusCode == 401 {
            // Token expired or invalid
            _ = KeychainManager.shared.deleteToken()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: AuthInterceptor.sessionDidExpireNotification, object: nil)
            }
        }
    }
}
