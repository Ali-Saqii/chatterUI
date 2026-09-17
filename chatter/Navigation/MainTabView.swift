//
//  MainTabView.swift
//  chatter
//

import SwiftUI

enum TabSelection: Int, Hashable {
    case feed = 0
    case people = 1
    case profile = 2
    case settings = 3
}

struct MainTabView: View {
    @State private var selectedTab: TabSelection = .feed
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Feed
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: selectedTab == .feed ? "house.fill" : "house")
            }
            .tag(TabSelection.feed)
            
            // Tab 2: People
            NavigationStack {
                PeopleView()
            }
            .tabItem {
                Label("People", systemImage: selectedTab == .people ? "person.2.fill" : "person.2")
            }
            .tag(TabSelection.people)
            
            // Tab 3: Profile
            NavigationStack {
                ProfileView(username: nil)
            }
            .tabItem {
                Label("Profile", systemImage: selectedTab == .profile ? "person.crop.circle.fill" : "person.crop.circle")
            }
            .tag(TabSelection.profile)
            
            // Tab 4: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
            }
            .tag(TabSelection.settings)
        }
        .tint(Color.chatterPrimary)
    }
}

#Preview("Main Tab View") {
    let state = AppState()
    state.setAuthenticated(token: "mock_token", user: User.mock)
    return MainTabView()
        .environmentObject(state)
}
