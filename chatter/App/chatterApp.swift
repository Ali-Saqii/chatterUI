//
//  chatterApp.swift
//  chatter
//

import SwiftUI
import CoreData

@main
struct ChatterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    private let persistence = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
