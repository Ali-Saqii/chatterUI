//
//  ProfileView.swift
//  chatter
//

import SwiftUI

struct ProfileView: View {
    let username: String?
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    @State private var viewMode: Int = 0 // 0: Grid, 1: Feed
    
    init(username: String? = nil) {
        self.username = username
        _viewModel = StateObject(wrappedValue: ProfileViewModel(targetUsername: username))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoadingProfile && viewModel.user == nil {
                    // Profile Skeleton
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.chatterSubtext.opacity(0.15))
                            .frame(width: 88, height: 88)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.chatterSubtext.opacity(0.18))
                            .frame(width: 140, height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.chatterSubtext.opacity(0.12))
                            .frame(width: 90, height: 12)
                    }
                    .padding(.top, 24)
                    .shimmering()
                } else if let user = viewModel.user {
                    // Header Section
                    VStack(spacing: 16) {
                        AvatarView(urlString: user.avatarURL, name: user.fullName, size: 88)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.chatterTitle)
                                .foregroundColor(.chatterText)
                            
                            Text("@\(user.username)")
                                .font(.chatterSubheadline)
                                .foregroundColor(.chatterSubtext)
                        }
                        
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.chatterBody)
                                .foregroundColor(.chatterText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Posts & Friends Counts ONLY (no Followers/Following)
                        HStack(spacing: 40) {
                            VStack(spacing: 2) {
                                Text("\(user.postsCount)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(.chatterText)
                                Text("Posts")
                                    .font(.chatterCaption)
                                    .foregroundColor(.chatterSubtext)
                            }
                            
                            Divider()
                                .frame(height: 28)
                            
                            VStack(spacing: 2) {
                                Text("\(user.friendsCount)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(.chatterText)
                                Text("Friends")
                                    .font(.chatterCaption)
                                    .foregroundColor(.chatterSubtext)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Dynamic Action Button
                        profileActionButton(for: user)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 12)
                    
                    // View Mode Switcher
                    Picker("View Mode", selection: $viewMode) {
                        Image(systemName: "squareshape.split.3x3").tag(0)
                        Image(systemName: "rectangle.grid.1x2").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    // Posts Content
                    if viewModel.isLoadingPosts && viewModel.posts.isEmpty {
                        ProgressView()
                            .padding(.top, 30)
                    } else if viewModel.posts.isEmpty {
                        EmptyStateView(
                            icon: "photo.on.rectangle.angled",
                            title: "No Posts Yet",
                            description: "Posts shared by \(user.fullName) will appear here."
                        )
                    } else {
                        if viewMode == 0 {
                            PostGridView(posts: viewModel.posts)
                                .padding(.horizontal, 2)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.posts) { post in
                                    NavigationLink(destination: PostDetailView(post: post)) {
                                        PostRowView(post: post)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle(username != nil ? "@\(username!)" : "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadProfile(currentUser: appState.currentUser)
        }
        .task {
            await viewModel.loadProfile(currentUser: appState.currentUser)
        }
        .sheet(isPresented: $viewModel.showEditProfileSheet) {
            NavigationStack {
                EditProfileView(viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private func profileActionButton(for user: User) -> some View {
        switch viewModel.friendActionState {
        case .editProfile:
            PrimaryButton(
                title: "Edit Profile",
                icon: "pencil",
                style: .outline,
                height: 40
            ) {
                viewModel.showEditProfileSheet = true
            }
            
        case .addFriend:
            PrimaryButton(
                title: "Add Friend",
                icon: "person.badge.plus",
                style: .primary,
                height: 40
            ) {
                Task {
                    await viewModel.sendFriendRequest(targetUserId: user.id)
                }
            }
            
        case .requestSent(let requestId):
            PrimaryButton(
                title: "Request Sent",
                icon: "clock.fill",
                style: .secondary,
                height: 40
            ) {
                if let reqId = requestId {
                    Task {
                        await viewModel.cancelFriendRequest(requestId: reqId)
                    }
                }
            }
            
        case .requestReceived(let requestId):
            HStack(spacing: 12) {
                PrimaryButton(
                    title: "Accept",
                    icon: "checkmark",
                    style: .primary,
                    height: 40
                ) {
                    Task {
                        await viewModel.acceptFriendRequest(requestId: requestId)
                    }
                }
                
                PrimaryButton(
                    title: "Decline",
                    icon: "xmark",
                    style: .outline,
                    height: 40
                ) {
                    Task {
                        await viewModel.declineFriendRequest(requestId: requestId)
                    }
                }
            }
            
        case .friends(let friendId):
            Menu {
                Button(role: .destructive, action: {
                    if let fid = friendId ?? viewModel.user?.id {
                        Task {
                            await viewModel.removeFriend(friendId: fid)
                        }
                    }
                }) {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.chatterSuccess)
                    Text("Friends")
                        .font(.chatterHeadline)
                        .foregroundColor(.chatterText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.chatterSubtext)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.chatterInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
        case .loading:
            ProgressView()
                .frame(height: 40)
        }
    }
}
