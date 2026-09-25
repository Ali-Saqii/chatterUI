//
//  NewChatSheetView.swift
//  chatter
//

import SwiftUI

struct NewChatSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: ChatListViewModel
    
    var onConversationCreated: (Conversation) -> Void
    
    @State private var isGroupMode: Bool = false
    @State private var groupName: String = ""
    @State private var selectedUserIds: Set<String> = []
    @State private var isCreating: Bool = false
    @State private var searchQuery: String = ""
    @State private var selectedTab: Int = 0 // 0: All People, 1: Friends
    
    // Deduplicated list of all available community users excluding current user
    private var allAvailableUsers: [User] {
        var seen = Set<String>()
        var list: [User] = []
        let currentId = appState.currentUser?.id
        for user in (viewModel.friends + viewModel.allUsers) {
            if user.id != currentId && !seen.contains(user.id) {
                seen.insert(user.id)
                list.append(user)
            }
        }
        return list
    }
    
    private var friendUsers: [User] {
        let currentId = appState.currentUser?.id
        return viewModel.friends.filter { $0.id != currentId }
    }
    
    private var displayedUsers: [User] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty {
            let pool = !viewModel.searchResults.isEmpty ? viewModel.searchResults : allAvailableUsers
            let currentId = appState.currentUser?.id
            var seen = Set<String>()
            return pool.filter { user in
                guard user.id != currentId && !seen.contains(user.id) else { return false }
                seen.insert(user.id)
                return user.fullName.lowercased().contains(trimmed) || user.username.lowercased().contains(trimmed)
            }
        }
        
        if selectedTab == 1 {
            return friendUsers
        } else {
            return allAvailableUsers
        }
    }
    
    private var selectedUsersList: [User] {
        allAvailableUsers.filter { selectedUserIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Mode Picker: Direct vs Group
                Picker("Chat Type", selection: $isGroupMode) {
                    Text("Direct Chat").tag(false)
                    Text("New Group").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.chatterCardBackground)
                
                // Group Name Input (only for group mode)
                if isGroupMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Details")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                        
                        HStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.chatterPrimary)
                                .font(.system(size: 16))
                            
                            TextField("Enter group name...", text: $groupName)
                                .font(.chatterBody)
                                .autocorrectionDisabled()
                            
                            if !groupName.isEmpty {
                                Button(action: { groupName = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.chatterSubtext)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.chatterInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        // Selected participants chips horizontal bar
                        if !selectedUsersList.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Selected Participants (\(selectedUsersList.count))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.chatterSubtext)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(selectedUsersList) { user in
                                            HStack(spacing: 6) {
                                                AvatarView(urlString: user.avatarURL, name: user.fullName, size: 24)
                                                
                                                Text(user.fullName.components(separatedBy: " ").first ?? user.username)
                                                    .font(.chatterCaptionBold)
                                                    .foregroundColor(.chatterText)
                                                    .lineLimit(1)
                                                
                                                Button(action: {
                                                    selectedUserIds.remove(user.id)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.chatterSubtext)
                                                }
                                            }
                                            .padding(.leading, 4)
                                            .padding(.trailing, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.chatterCardBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.chatterPrimary.opacity(0.3), lineWidth: 1))
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.chatterCardBackground)
                }
                
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.chatterSubtext)
                    
                    TextField("Search users by name or @username...", text: $searchQuery)
                        .font(.chatterBody)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchQuery) { _, newValue in
                            Task {
                                await viewModel.searchUsers(query: newValue)
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            viewModel.searchResults = []
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
                .padding(.vertical, 8)
                
                // Scope Filter Tabs (All People vs Friends)
                if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 8) {
                        scopeTabButton(title: "All People (\(allAvailableUsers.count))", tag: 0)
                        scopeTabButton(title: "Friends (\(friendUsers.count))", tag: 1)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                
                Divider()
                    .padding(.top, 4)
                
                // Users Content
                if (viewModel.isLoadingFriends || viewModel.isLoadingUsers) && allAvailableUsers.isEmpty {
                    Spacer()
                    ProgressView("Loading users...")
                        .tint(.chatterPrimary)
                    Spacer()
                } else if displayedUsers.isEmpty {
                    Spacer()
                    if !searchQuery.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Users Found",
                            description: "No users match '\(searchQuery)'. Try searching with another name."
                        )
                    } else if selectedTab == 1 {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.chatterSubtext.opacity(0.6))
                            Text("No Friends Yet")
                                .font(.chatterHeadline)
                                .foregroundColor(.chatterText)
                            Text("You haven't added friends yet, but you can chat with anyone from All People!")
                                .font(.chatterCaption)
                                .foregroundColor(.chatterSubtext)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button(action: {
                                selectedTab = 0
                            }) {
                                Text("Browse All People")
                                    .font(.chatterCaptionBold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.chatterGradient)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        EmptyStateView(
                            icon: "person.3.sequence.fill",
                            title: "No Users Available",
                            description: "No registered users found in the community."
                        )
                    }
                    Spacer()
                } else {
                    List {
                        Section(header: Text(isGroupMode ? "Select Participants (\(selectedUserIds.count) selected)" : (selectedTab == 1 ? "Your Friends" : "All Community Users"))) {
                            ForEach(displayedUsers) { user in
                                userRow(for: user)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color.chatterBackground.ignoresSafeArea())
            .navigationTitle(isGroupMode ? "Create Group" : "New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if isGroupMode {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: createGroupChat) {
                            if isCreating {
                                ProgressView()
                                    .tint(.chatterPrimary)
                            } else {
                                Text(selectedUserIds.isEmpty ? "Create" : "Create (\(selectedUserIds.count))")
                                    .bold()
                            }
                        }
                        .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedUserIds.isEmpty || isCreating)
                    }
                }
            }
            .task {
                await viewModel.loadNewChatData()
                // Default to All People if user has 0 friends
                if viewModel.friends.isEmpty && !viewModel.allUsers.isEmpty {
                    selectedTab = 0
                }
            }
        }
    }
    
    @ViewBuilder
    private func scopeTabButton(title: String, tag: Int) -> some View {
        Button(action: {
            selectedTab = tag
        }) {
            Text(title)
                .font(.system(size: 13, weight: selectedTab == tag ? .bold : .medium))
                .foregroundColor(selectedTab == tag ? .white : .chatterSubtext)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    selectedTab == tag
                    ? AnyShapeStyle(Color.chatterGradient)
                    : AnyShapeStyle(Color.chatterInputBackground)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func userRow(for user: User) -> some View {
        let isSelected = selectedUserIds.contains(user.id)
        let isFriend = viewModel.friends.contains(where: { $0.id == user.id })
        
        Button(action: {
            if isGroupMode {
                if isSelected {
                    selectedUserIds.remove(user.id)
                } else {
                    selectedUserIds.insert(user.id)
                }
            } else {
                startDirectChat(with: user)
            }
        }) {
            HStack(spacing: 12) {
                AvatarView(
                    urlString: user.avatarURL,
                    name: user.fullName,
                    size: 44
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user.fullName)
                            .font(.chatterHeadline)
                            .foregroundColor(.chatterText)
                            .lineLimit(1)
                        
                        if isFriend {
                            Text("Friend")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.chatterSuccess)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.chatterSuccess.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("@\(user.username)")
                        .font(.chatterCaption)
                        .foregroundColor(.chatterSubtext)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isGroupMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .chatterPrimary : .chatterSubtext.opacity(0.4))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.chatterSubtext.opacity(0.4))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func startDirectChat(with user: User) {
        guard !isCreating else { return }
        Task {
            isCreating = true
            if let conv = await viewModel.createDirectConversation(user: user) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onConversationCreated(conv)
                }
            }
            isCreating = false
        }
    }
    
    private func createGroupChat() {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !selectedUserIds.isEmpty, !isCreating else { return }
        
        Task {
            isCreating = true
            let selected = allAvailableUsers.filter { selectedUserIds.contains($0.id) }
            if let conv = await viewModel.createGroupConversation(
                participantIds: Array(selectedUserIds),
                groupName: name,
                selectedUsers: selected
            ) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onConversationCreated(conv)
                }
            }
            isCreating = false
        }
    }
}
