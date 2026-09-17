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
                            tileContent(for: post)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink(destination: PostDetailView(post: post)) {
                            tileContent(for: post)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func tileContent(for post: Post) -> some View {
        ZStack {
            Color.chatterInputBackground
            
            if post.mediaType != .none, let mediaURL = post.mediaURL {
                MediaPlayerView(mediaURL: mediaURL, mediaType: post.mediaType, maxHeight: 120)
                    .clipped()
            } else {
                // Text post tile
                VStack {
                    Text(post.text ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.chatterText)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .padding(8)
                }
            }
        }
        .frame(height: 120)
        .contentShape(Rectangle())
    }
}

#Preview("Post Grid") {
    ScrollView {
        PostGridView(posts: Post.mockList)
    }
    .background(Color.chatterBackground)
}
