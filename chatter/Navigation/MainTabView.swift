//
//  MainTabView.swift
//  chatter
//

import SwiftUI

enum TabSelection: Int, Hashable {
    case feed = 0
    case people = 1
    case chat = 2
    case profile = 3
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
                Label("Feed", systemImage: "house")
            }
            .tag(TabSelection.feed)
            
            // Tab 2: People
            NavigationStack {
                PeopleView()
            }
            .tabItem {
                Label("People", systemImage: "person.2")
            }
            .tag(TabSelection.people)
            
            // Tab 3: Chat
            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(TabSelection.chat)
            
            // Tab 4: Profile
            NavigationStack {
                ProfileView(username: nil)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(TabSelection.profile)
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
