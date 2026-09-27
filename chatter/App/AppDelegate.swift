//
//  AppDelegate.swift
//  chatter
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationManager.shared.setup()
        
        // Check if the app was launched by tapping a push notification when closed
        if let notificationPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationManager.shared.handleRemoteNotification(userInfo: notificationPayload)
            }
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ [AppDelegate] Remote notification registration failed: \(error.localizedDescription)")
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationManager.shared.handleRemoteNotification(userInfo: userInfo)
        completionHandler(.newData)
    }
}
