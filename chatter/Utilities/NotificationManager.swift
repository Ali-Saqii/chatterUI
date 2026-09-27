//
//  NotificationManager.swift
//  chatter
//

import Foundation
import UserNotifications
import UIKit
import Combine

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isPermissionGranted: Bool = false
    @Published var deviceTokenString: String? = nil
    
    private override init() {
        super.init()
    }
    
    /// Initialize notification center delegate and request system permissions
    func setup() {
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }
    
    /// Request user permission for alerts, badges, and sounds
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("✅ [NotificationManager] Notification permissions granted")
                } else if let error = error {
                    print("❌ [NotificationManager] Permission error: \(error.localizedDescription)")
                } else {
                    print("⚠️ [NotificationManager] Notification permissions denied by user")
                }
            }
        }
    }
    
    /// Handle APNs Device Token from AppDelegate
    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        DispatchQueue.main.async {
            self.deviceTokenString = token
            UserDefaults.standard.set(token, forKey: "apns_device_token")
            print("📱 [NotificationManager] APNs Device Token registered: \(token)")
        }
    }
    
    /// Schedule a system notification for incoming notification events
    /// Works whether app is active, in background, or closed!
    func scheduleLocalNotification(from notification: AppNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.actor.fullName.isEmpty ? "Chatter" : notification.actor.fullName
        content.body = notification.message
        content.sound = .default
        
        if #available(iOS 17.0, *) {
            // iOS 17 handles badge via UNUserNotificationCenter.setBadgeCount
        } else {
            content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        }
        
        var userInfo: [String: Any] = [
            "id": notification.id,
            "type": notification.type.rawValue,
            "entityType": notification.entityType ?? "",
            "entityId": notification.entityId ?? "",
            "actorUsername": notification.actor.username,
            "actorName": notification.actor.fullName,
            "actorId": notification.actor.id
        ]
        if let avatar = notification.actor.avatarURL {
            userInfo["actorAvatar"] = avatar
        }
        if let convId = notification.metadata?.conversationId {
            userInfo["conversationId"] = convId
        }
        content.userInfo = userInfo
        
        // Immediate trigger for system banner display
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NotificationManager] Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("🔔 [NotificationManager] System notification banner scheduled: \(notification.message)")
            }
        }
    }
    
    /// Process incoming background remote push payload
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("📩 [NotificationManager] Remote notification received: \(userInfo)")
        Task { @MainActor in
            NotificationRouter.shared.routeFromUserInfo(userInfo)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// 1. App is in Foreground: Present native banner, sound, and badge just like Instagram/Facebook!
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// 2. User tapped on the notification banner (when app was closed, in background, or in foreground)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("🎯 [NotificationManager] User clicked notification banner: \(userInfo)")
        
        Task { @MainActor in
            NotificationRouter.shared.routeFromUserInfo(userInfo)
        }
        
        completionHandler()
    }
}
