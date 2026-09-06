//
//  RootView.swift
//  chatter
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if appState.isAuthenticated {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    AuthCoordinator()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
            
            // Global Banner Overlay
            if let banner = appState.banner {
                ErrorBanner(banner: banner) {
                    appState.dismissBanner()
                }
                .padding(.top, 8)
                .zIndex(999)
            }
        }
    }
}
