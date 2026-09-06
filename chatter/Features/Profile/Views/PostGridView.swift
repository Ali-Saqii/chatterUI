//
//  PostGridView.swift
//  chatter
//

import SwiftUI

struct PostGridView: View {
    let posts: [Post]
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                NavigationLink(destination: PostDetailView(post: post)) {
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
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
