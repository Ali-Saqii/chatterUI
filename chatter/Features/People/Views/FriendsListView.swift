//
//  FriendsListView.swift
//  chatter
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: PeopleViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoadingFriends && viewModel.friends.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            UserSkeletonView()
                        }
                    }
                    .padding(.top, 12)
                }
            } else if viewModel.friends.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Friends Yet",
                    description: "Connect with people by sending them a friend request in the 'All People' tab."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.friends) { friend in
                            UserRowView(user: friend) {
                                Menu {
                                    Button(role: .destructive, action: {
                                        Task {
                                            await viewModel.removeFriend(user: friend)
                                        }
                                    }) {
                                        Label("Remove Friend", systemImage: "person.badge.minus")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Friends")
                                            .font(.chatterCaptionBold)
                                            .foregroundColor(.chatterText)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10))
                                            .foregroundColor(.chatterSubtext)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.chatterInputBackground)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .refreshable {
            await viewModel.fetchFriends()
        }
    }
}
#Preview("Friends List") {
    let vm = PeopleViewModel()
    vm.friends = User.mockList
    return NavigationStack {
        FriendsListView(viewModel: vm)
            .background(Color.chatterBackground)
    }
}
