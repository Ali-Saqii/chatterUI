//
//  PeopleView.swift
//  chatter
//

import SwiftUI

struct PeopleView: View {
    @StateObject private var viewModel = PeopleViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Segmented Picker
            Picker("Section", selection: $viewModel.selectedTab) {
                Text("All People").tag(0)
                Text("Friends").tag(1)
                Text("Requests").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.chatterCardBackground)
            
            // Content according to selected tab
            Group {
                switch viewModel.selectedTab {
                case 0:
                    allPeopleContent
                case 1:
                    FriendsListView(viewModel: viewModel)
                case 2:
                    RequestsView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchFriends()
            await viewModel.fetchRequests()
        }
        .task(id: viewModel.searchQuery) {
            if !viewModel.searchQuery.isEmpty {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            await viewModel.searchUsers()
        }
    }
    
    @ViewBuilder
    private var allPeopleContent: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.chatterSubtext)
                
                TextField("Search by name or @username...", text: $viewModel.searchQuery)
                    .font(.chatterBody)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        Task {
                            await viewModel.searchUsers()
                        }
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                        Task {
                            await viewModel.searchUsers()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.chatterSubtext)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.chatterInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // User List
            if viewModel.isLoadingUsers && viewModel.allUsers.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            UserSkeletonView()
                        }
                    }
                    .padding(.top, 8)
                }
            } else if viewModel.allUsers.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "No Users Found",
                    description: "Try searching with a different name or username."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.allUsers) { user in
                            UserRowView(user: user) {
                                userActionView(for: user)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .refreshable {
                    await viewModel.searchUsers()
                    await viewModel.fetchFriends()
                    await viewModel.fetchRequests()
                }
            }
        }
    }
    
    @ViewBuilder
    private func userActionView(for user: User) -> some View {
        if user.id == appState.currentUser?.id || user.username == appState.currentUser?.username {
            Text("You")
                .font(.chatterCaptionBold)
                .foregroundColor(.chatterSubtext)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.chatterInputBackground)
                .clipShape(Capsule())
        } else if viewModel.friendUserIds.contains(user.id) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                Text("Friends")
                    .font(.chatterCaptionBold)
            }
            .foregroundColor(.chatterSuccess)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.chatterSuccess.opacity(0.12))
            .clipShape(Capsule())
        } else if viewModel.sentRequestUserIds.contains(user.id) {
            Text("Requested")
                .font(.chatterCaptionBold)
                .foregroundColor(.chatterSubtext)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.chatterInputBackground)
                .clipShape(Capsule())
        } else {
            Button(action: {
                Task {
                    await viewModel.sendFriendRequest(to: user)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add")
                        .font(.chatterCaptionBold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.chatterGradient)
                .clipShape(Capsule())
                .shadow(color: Color.chatterPrimary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
}
#Preview {
    PeopleView()
        .environmentObject(AppState())
}
