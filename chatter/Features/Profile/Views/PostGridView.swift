//
//  PostGridView.swift
//  chatter
//

import SwiftUI

struct PostGridView: View {
    let posts: [Post]
    var onPostTapped: ((Post) -> Void)? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                Group {
                    if let onPostTapped = onPostTapped {
                        Button(action: {
                            onPostTapped(post)
                        }) {
                            gridSquare(for: post)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink(destination: PostDetailView(post: post)) {
                            gridSquare(for: post)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func gridSquare(for post: Post) -> some View {
        Color.chatterInputBackground
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                tileContent(for: post)
            )
            .clipped()
            .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func tileContent(for post: Post) -> some View {
        ZStack {
            if post.mediaType != .none, let mediaURL = post.mediaURL, let resolved = URLResolver.resolve(mediaURL) {
                AsyncImage(url: resolved) { phase in
                    switch phase {
                    case .empty:
                        Color.chatterInputBackground
                            .overlay(ProgressView().scaleEffect(0.7))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Color.chatterInputBackground
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.chatterSubtext)
                            )
                    @unknown default:
                        Color.chatterInputBackground
                    }
                }
                
                // Instagram-style video badge in top-right
                if post.mediaType == .video {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.black.opacity(0.45))
                                .clipShape(Circle())
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            } else {
                // Instagram-style text post card
                ZStack {
                    LinearGradient(
                        colors: [Color.chatterCardBackground, Color.chatterInputBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 6) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.chatterPrimary.opacity(0.7))
                        
                        Text(post.text ?? "")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.chatterText)
                            .lineLimit(4)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 6)
                    }
                    .padding(4)
                }
            }
        }
    }
}

#Preview("Post Grid") {
    ScrollView {
        PostGridView(posts: Post.mockList)
    }
    .background(Color.chatterBackground)
}
