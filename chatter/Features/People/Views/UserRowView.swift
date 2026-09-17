//
//  UserRowView.swift
//  chatter
//

import SwiftUI

struct UserRowView<ActionContent: View>: View {
    let user: User
    let actionView: ActionContent
    
    init(user: User, @ViewBuilder actionView: () -> ActionContent) {
        self.user = user
        self.actionView = actionView()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ProfileView(username: user.username)) {
                HStack(spacing: 12) {
                    AvatarView(urlString: user.avatarURL, name: user.fullName, size: 46)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.fullName)
                            .font(.chatterHeadline)
                            .foregroundColor(.chatterText)
                            .lineLimit(1)
                        
                        Text("@\(user.username)")
                            .font(.chatterCaption)
                            .foregroundColor(.chatterSubtext)
                            .lineLimit(1)
                        
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.chatterCaption)
                                .foregroundColor(.chatterTertiaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            actionView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.chatterCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension UserRowView where ActionContent == EmptyView {
    init(user: User) {
        self.init(user: user, actionView: { EmptyView() })
    }
}

#Preview("User Row Variations") {
    VStack(spacing: 12) {
        UserRowView(user: User.mock)
        
        UserRowView(user: User.mockList[1]) {
            Button(action: {}) {
                Text("Add")
                    .font(.chatterCaptionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.chatterGradient)
                    .clipShape(Capsule())
            }
        }
    }
    .padding()
    .background(Color.chatterBackground)
}
