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
    
    private var isOwnPost: Bool {
        guard let current = appState.currentUser else { return false }
        return current.id == post.author.id || current.username == post.author.username
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Author Header
            HStack(spacing: 12) {
                NavigationLink(destination: ProfileView(username: post.author.username)) {
                    HStack(spacing: 12) {
                        AvatarView(urlString: post.author.avatarURL, name: post.author.fullName, size: 42)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.author.fullName)
                                .font(.chatterHeadline)
                                .foregroundColor(.chatterText)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Text("@\(post.author.username)")
                                    .font(.chatterCaption)
                                    .foregroundColor(.chatterSubtext)
                                
                                if let createdAt = post.createdAt {
                                    Text("•")
                                        .font(.chatterCaption)
                                        .foregroundColor(.chatterTertiaryText)
                                    Text(createdAt.timeAgoDisplay())
                                        .font(.chatterCaption)
                                        .foregroundColor(.chatterSubtext)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // More / Delete Menu
                if isOwnPost {
                    Menu {
                        Button(role: .destructive, action: {
                            onDeleteTapped?()
                        }) {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.chatterSubtext)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                }
            }
            
            // Post Text
            if let text = post.text, !text.isEmpty {
                Text(text)
                    .font(.chatterBody)
                    .foregroundColor(.chatterText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPostTapped?()
                    }
            }
            
            // Media Preview
            if post.mediaType != .none, let _ = post.mediaURL {
                MediaPlayerView(mediaURL: post.mediaURL, mediaType: post.mediaType, allowsFullScreen: allowsFullScreen)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !allowsFullScreen {
                            onPostTapped?()
                        }
                    }
            }
            
            // Post Actions Bar
            HStack(spacing: 24) {
                // Like Button
                Button(action: {
                    onLikeTapped?()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(post.isLikedByMe ? .chatterDestructive : .chatterSubtext)
                            .scaleEffect(post.isLikedByMe ? 1.15 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: post.isLikedByMe)
                        
                        Text("\(post.likesCount)")
                            .font(.chatterCaptionBold)
                            .foregroundColor(post.isLikedByMe ? .chatterDestructive : .chatterSubtext)
                    }
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
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 17))
                            .foregroundColor(.chatterSubtext)
                        
                        Text("\(post.commentsCount)")
                            .font(.chatterCaptionBold)
                            .foregroundColor(.chatterSubtext)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Share button
                ShareLink(item: post.text ?? "Check out this post on Chatter!") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.chatterSubtext)
                }
                
                // Download button — only shown when post has media
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
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "arrow.down.to.line.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.chatterSubtext)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(downloadManager.isDownloading)
                }
            }
            .padding(.top, 4)
        }
        .chatterCard()
        .downloadToast(manager: downloadManager)
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

