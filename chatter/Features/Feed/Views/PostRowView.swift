//
//  PostRowView.swift
//  chatter
//

import SwiftUI

struct PostRowView: View {
    let post: Post
    var allowsFullScreen: Bool = false
    var onPostTapped: (() -> Void)? = nil
    var onLikeTapped: (() -> Void)? = nil
    var onDeleteTapped: (() -> Void)? = nil
    var onCommentTapped: (() -> Void)? = nil
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var downloadManager = DownloadManager()
    @State private var isSaved: Bool = false
    @State private var isCaptionExpanded: Bool = false
    @State private var showHeartAnimation: Bool = false
    
    private var isOwnPost: Bool {
        guard let current = appState.currentUser else { return false }
        return current.id == post.author.id || current.username == post.author.username
    }
    
    private var hasMedia: Bool {
        post.mediaType != .none && post.mediaURL != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Author Header (Instagram Style)
            authorHeaderView
            
            // 2. Media / Post Content (Hero)
            postContentView
            
            // 3. Action Bar (Like, Comment, Share, Save)
            actionButtonsBar
            
            // 4. Likes Count
            if post.likesCount > 0 {
                Text("\(post.likesCount) likes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.chatterText)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
            }
            
            // 5. Caption (Instagram Style: Bold username + caption text below media)
            if hasMedia, let text = post.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                captionView(text: text)
            }
            
            // 6. Comments Link
            if post.commentsCount > 0 {
                Button(action: {
                    if let onCommentTapped = onCommentTapped {
                        onCommentTapped()
                    } else {
                        onPostTapped?()
                    }
                }) {
                    Text("View all \(post.commentsCount) comments")
                        .font(.system(size: 13))
                        .foregroundColor(.chatterSubtext)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            
            // 7. Timestamp
            if let createdAt = post.createdAt {
                Text(createdAt.timeAgoDisplay().uppercased())
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.chatterTertiaryText)
                    .padding(.horizontal, 14)
                    .padding(.top, 5)
                    .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 10)
            }
        }
        .background(Color.chatterCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.chatterBorder.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .downloadToast(manager: downloadManager)
    }
    
    // MARK: - Author Header
    private var authorHeaderView: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: ProfileView(username: post.author.username)) {
                HStack(spacing: 10) {
                    AvatarView(urlString: post.author.avatarURL, name: post.author.fullName, size: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.chatterBorder.opacity(0.25), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(post.author.username)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.chatterText)
                                .lineLimit(1)
                            
                            if let createdAt = post.createdAt {
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(.chatterTertiaryText)
                                Text(createdAt.timeAgoDisplay())
                                    .font(.system(size: 12))
                                    .foregroundColor(.chatterSubtext)
                            }
                        }
                        
                        if !post.author.fullName.isEmpty && post.author.fullName != post.author.username {
                            Text(post.author.fullName)
                                .font(.system(size: 11))
                                .foregroundColor(.chatterSubtext)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Trailing Options Menu
            Menu {
                if isOwnPost {
                    Button(role: .destructive, action: {
                        onDeleteTapped?()
                    }) {
                        Label("Delete Post", systemImage: "trash")
                    }
                }
                
                ShareLink(item: post.text ?? "Check out this post on Chatter!") {
                    Label("Share Post", systemImage: "paperplane")
                }
                
                if let text = post.text, !text.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = text
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.chatterSubtext)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Post Content (Media or Rich Text)
    @ViewBuilder
    private var postContentView: some View {
        if hasMedia {
            ZStack {
                MediaPlayerView(
                    mediaURL: post.mediaURL,
                    mediaType: post.mediaType,
                    maxHeight: 380,
                    allowsFullScreen: allowsFullScreen
                )
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    // Instagram Double-Tap to Like
                    if !post.isLikedByMe {
                        onLikeTapped?()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showHeartAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showHeartAnimation = false
                        }
                    }
                }
                .onTapGesture(count: 1) {
                    if !allowsFullScreen {
                        onPostTapped?()
                    }
                }
                
                // Animated popping heart for double-tap
                if showHeartAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 85))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
                        .scaleEffect(showHeartAnimation ? 1.0 : 0.3)
                        .opacity(showHeartAnimation ? 1.0 : 0.0)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        } else if let text = post.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Text-only post with clean, modern layout
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.chatterText)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .onTapGesture {
                    onPostTapped?()
                }
        }
    }
    
    // MARK: - Action Buttons Bar (Instagram Style)
    private var actionButtonsBar: some View {
        HStack(spacing: 16) {
            // Like Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onLikeTapped?()
            }) {
                Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(post.isLikedByMe ? .chatterDestructive : .chatterText)
                    .scaleEffect(post.isLikedByMe ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: post.isLikedByMe)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Comment Button
            Button(action: {
                if let onCommentTapped = onCommentTapped {
                    onCommentTapped()
                } else {
                    onPostTapped?()
                }
            }) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 20))
                    .foregroundColor(.chatterText)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Share Button (Iconic Paperplane)
            ShareLink(item: post.text ?? "Check out this post on Chatter!") {
                Image(systemName: "paperplane")
                    .font(.system(size: 20))
                    .foregroundColor(.chatterText)
            }
            
            Spacer()
            
            // Download Button (Only when post has media)
            if post.mediaType != .none, let mediaURL = post.mediaURL {
                Button(action: {
                    Task {
                        await downloadManager.download(
                            urlString: mediaURL,
                            mediaType: post.mediaType
                        )
                    }
                }) {
                    if downloadManager.isDownloading {
                        ProgressView()
                            .scaleEffect(0.75)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 19))
                            .foregroundColor(.chatterText)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(downloadManager.isDownloading)
            }
            
            // Save / Bookmark Button
            Button(action: {
                isSaved.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundColor(.chatterText)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
    
    // MARK: - Caption View
    private func captionView(text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            (
                Text(post.author.username).fontWeight(.semibold) +
                Text(" ") +
                Text(text)
            )
            .font(.system(size: 13))
            .foregroundColor(.chatterText)
            .lineLimit(isCaptionExpanded ? nil : 2)
            .multilineTextAlignment(.leading)
            
            if text.count > 90 && !isCaptionExpanded {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCaptionExpanded = true
                    }
                }) {
                    Text("more")
                        .font(.system(size: 13))
                        .foregroundColor(.chatterSubtext)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }
}

#Preview("Post Row Variations") {
    ScrollView {
        VStack(spacing: 16) {
            PostRowView(post: Post.mock)
            PostRowView(post: Post.mockList[1])
            PostRowView(post: Post.mockList[2])
        }
        .padding()
    }
    .background(Color.chatterBackground)
}
