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
    @State private var selectedPostForDetail: Post? = nil
    
    init(username: String? = nil) {
        self.username = username
        _viewModel = StateObject(wrappedValue: ProfileViewModel(targetUsername: username))
    }
    
    private var isMyProfile: Bool {
        username == nil || username == appState.currentUser?.username
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if viewModel.isLoadingProfile && viewModel.user == nil {
                    skeletonHeader
                } else if let user = viewModel.user {
                    // 1. Top Instagram Header: Avatar + Stats
                    HStack(alignment: .center, spacing: 24) {
                        // Story-Ring Avatar
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.98, green: 0.40, blue: 0.20),
                                            Color(red: 0.88, green: 0.20, blue: 0.55),
                                            Color(red: 0.58, green: 0.22, blue: 0.88)
                                        ],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                                .frame(width: 86, height: 86)
                            
                            AvatarView(urlString: user.avatarURL, name: user.fullName, size: 76)
                        }
                        
                        // Stats: Posts & Friends
                        HStack(spacing: 36) {
                            statItem(count: user.postsCount, label: "posts")
                            statItem(count: user.friendsCount, label: "friends")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // 2. Full Name & Bio (Instagram Style)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.fullName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.chatterText)
                        
                        Text("@\(user.username)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.chatterSubtext)
                        
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundColor(.chatterText)
                                .lineLimit(6)
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // 3. Instagram Action Buttons Row
                    HStack(spacing: 8) {
                        profileActionButton(for: user)
                        
                        if isMyProfile {
                            ShareLink(item: "Check out @\(user.username) on Chatter! chatter://profile/\(user.username)") {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Share profile")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.chatterText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(Color.chatterInputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            
                        } else {
                            ShareLink(item: "Check out @\(user.username) on Chatter!") {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.chatterText)
                                    .frame(width: 36, height: 34)
                                    .background(Color.chatterInputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
//                    // 4. Story Highlights (Instagram Signature)
//                    highlightsSection
                    
                    // 5. Instagram Tabs (Grid vs Feed)
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            tabButton(index: 0, icon: "squareshape.split.3x3")
                            tabButton(index: 1, icon: "rectangle.grid.1x2")
                        }
                        Divider()
                    }
                    .padding(.top, 4)
                    
                    // 6. Posts Content
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
                            PostGridView(posts: viewModel.posts) { post in
                                selectedPostForDetail = post
                            }
                            .padding(.horizontal, 1)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.posts) { post in
                                    PostRowView(
                                        post: post,
                                        onPostTapped: {
                                            selectedPostForDetail = post
                                        },
                                        onLikeTapped: {
                                            viewModel.toggleLike(for: post)
                                        },
                                        onDeleteTapped: {
                                            Task {
                                                await viewModel.deletePost(postId: post.id)
                                            }
                                        },
                                        onCommentTapped: {
                                            selectedPostForDetail = post
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                } else if viewModel.user == nil && !viewModel.isLoadingProfile {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.chatterSubtext)
                        Text(viewModel.errorMessage ?? "User not found")
                            .font(.chatterHeadline)
                            .foregroundColor(.chatterText)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadProfile(currentUser: appState.currentUser)
                            }
                        }
//                        .font(.system(size: 14, weight: .bold))
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 24)
//                        .padding(.vertical, 10)
//                        .background(Color.chatterPrimary)
//                        .clipShape(Capsule())
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle(viewModel.user != nil ? "@\(viewModel.user!.username)" : (username != nil ? "@\(username!)" : "Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isMyProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.chatterText)
                    }
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedPostForDetail != nil },
            set: { if !$0 { selectedPostForDetail = nil } }
        )) {
            if let post = selectedPostForDetail {
                PostDetailView(post: post) { updated in
                    viewModel.updatePost(updated)
                    selectedPostForDetail = updated
                }
            }
        }
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
    
    // MARK: - Story Highlights Section
    private var highlightsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                if isMyProfile {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(Color.chatterBorder, lineWidth: 1)
                                .frame(width: 60, height: 60)
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.chatterText)
                        }
                        Text("New")
                            .font(.system(size: 11))
                            .foregroundColor(.chatterText)
                    }
                }
                
                highlightItem(title: "Moments", icon: "sparkles")
                highlightItem(title: "Highlights", icon: "heart.fill")
                highlightItem(title: "Vibes", icon: "camera.fill")
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 4)
    }
    
    private func highlightItem(title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.chatterBorder.opacity(0.8), lineWidth: 1)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(Color.chatterInputBackground)
                    .frame(width: 54, height: 54)
                
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(.chatterPrimary)
            }
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.chatterText)
        }
    }
    
    // MARK: - Tab Button
    private func tabButton(index: Int, icon: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewMode = index
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: viewMode == index ? .semibold : .regular))
                    .foregroundColor(viewMode == index ? .chatterText : .chatterSubtext)
                
                Rectangle()
                    .fill(viewMode == index ? Color.chatterText : Color.clear)
                    .frame(height: 1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Stat Item
    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.chatterText)
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.chatterText)
        }
    }
    
    // MARK: - Skeleton Header
    private var skeletonHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 24) {
                Circle()
                    .fill(Color.chatterSubtext.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                HStack(spacing: 36) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.chatterSubtext.opacity(0.15))
                        .frame(width: 44, height: 28)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.chatterSubtext.opacity(0.15))
                        .frame(width: 44, height: 28)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.18))
                    .frame(width: 140, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.12))
                    .frame(width: 90, height: 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .shimmering()
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private func profileActionButton(for user: User) -> some View {
        switch viewModel.friendActionState {
        case .editProfile:
            Button(action: {
                viewModel.showEditProfileSheet = true
            }) {
                Text("Edit profile")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.chatterText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.chatterInputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
        case .addFriend:
            Button(action: {
                Task {
                    await viewModel.sendFriendRequest(targetUserId: user.id)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add Friend")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.chatterGradient)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: Color.chatterPrimary.opacity(0.25), radius: 4, y: 2)
            }
            
        case .requestSent(let requestId):
            Button(action: {
                if let reqId = requestId {
                    Task {
                        await viewModel.cancelFriendRequest(requestId: reqId)
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text("Requested")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.chatterSubtext)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.chatterInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
        case .requestReceived(let requestId):
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await viewModel.acceptFriendRequest(requestId: requestId)
                    }
                }) {
                    Text("Confirm")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.chatterGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                
                Button(action: {
                    Task {
                        await viewModel.declineFriendRequest(requestId: requestId)
                    }
                }) {
                    Text("Delete")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.chatterText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                HStack(spacing: 6) {
                    Text("Friends")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.chatterText)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.chatterInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
        case .loading:
            ProgressView()
                .frame(height: 34)
                .frame(maxWidth: .infinity)
        }
    }
}
#Preview("My Profile") {
    let state = AppState()
    state.setAuthenticated(token: "mock_token", user: User.mock)
    return NavigationStack {
        ProfileView(username: nil)
            .environmentObject(state)
    }
}

#Preview("Other User Profile") {
    let state = AppState()
    state.setAuthenticated(token: "mock_token", user: User.mock)
    return NavigationStack {
        ProfileView(username: "janedoe")
            .environmentObject(state)
    }
}
