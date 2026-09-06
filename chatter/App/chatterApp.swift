//
//  chatterApp.swift
//  chatter
//

import SwiftUI

@main
struct chatterApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
