//
//  NotificationRowView.swift
//  chatter
//

import SwiftUI

struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar with type badge overlay
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        urlString: notification.actor.avatarURL,
                        name: notification.actor.fullName,
                        size: 46
                    )
                    
                    // Notification type badge
                    ZStack {
                        Circle()
                            .fill(badgeBackground)
                            .frame(width: 22, height: 22)
                        
                        Circle()
                            .strokeBorder(Color.chatterCardBackground, lineWidth: 2)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Text(notification.actor.fullName).font(.chatterHeadline).foregroundColor(.chatterText)) \(Text(notification.message).font(.chatterBody).foregroundColor(.chatterSubtext))")
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text(notification.createdAt.timeAgoDisplay())
                        .font(.chatterCaption)
                        .foregroundColor(notification.isRead ? .chatterSubtext.opacity(0.6) : .chatterPrimary)
                }
                
                Spacer(minLength: 4)
                
                // Unread indicator dot
                if !notification.isRead {
                    Circle()
                        .fill(Color.chatterPrimary)
                        .frame(width: 10, height: 10)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(notification.isRead ? Color.clear : Color.chatterPrimary.opacity(0.04))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Badge Colors
    
    private var badgeBackground: Color {
        switch notification.type {
        case .like:
            return .chatterDestructive
        case .comment:
            return .chatterPrimary
        case .friendRequest, .friendRequestAccepted:
            return .chatterSuccess
        case .message:
            return .chatterPrimary
        }
    }
}

// MARK: - Preview

#Preview("Notification Rows") {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(AppNotification.mockList) { notif in
                NotificationRowView(notification: notif) {}
                Divider().padding(.leading, 74)
            }
        }
    }
    .background(Color.chatterBackground)
}
