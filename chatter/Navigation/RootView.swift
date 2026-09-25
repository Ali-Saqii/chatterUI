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
            
            // Offline and Global Banners
            VStack(spacing: 6) {
                OfflineBannerView()
                
                if let banner = appState.banner {
                    ErrorBanner(banner: banner) {
                        appState.dismissBanner()
                    }
                }
            }
            .padding(.top, 8)
            .zIndex(999)
        }
        .preferredColorScheme(appState.preferredColorScheme)
    }
}

#Preview("Root View - Unauthenticated") {
    RootView()
        .environmentObject(AppState())
}

#Preview("Root View - Authenticated") {
    let state = AppState()
    state.setAuthenticated(token: "mock_token", user: User.mock)
    return RootView()
        .environmentObject(state)
}
