//
//  CommentRowView.swift
//  chatter
//

import SwiftUI

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NavigationLink(destination: ProfileView(username: comment.author.username)) {
                AvatarView(urlString: comment.author.avatarURL, name: comment.author.fullName, size: 36)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.author.fullName)
                        .font(.chatterCaptionBold)
                        .foregroundColor(.chatterText)
                    
                    Text("@\(comment.author.username)")
                        .font(.chatterCaption)
                        .foregroundColor(.chatterSubtext)
                    
                    if let date = comment.createdAt {
                        Text("•")
                            .font(.chatterCaption)
                            .foregroundColor(.chatterTertiaryText)
                        Text(date.timeAgoDisplay())
                            .font(.chatterCaption)
                            .foregroundColor(.chatterSubtext)
                    }
                }
                
                Text(comment.text)
                    .font(.chatterBody)
                    .foregroundColor(.chatterText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview("Comment Row") {
    VStack(spacing: 12) {
        CommentRowView(comment: Comment.mockComments(for: "1")[0])
        CommentRowView(comment: Comment.mockComments(for: "1")[1])
    }
    .padding()
    .background(Color.chatterBackground)
}
