//
//  EmptyStateView.swift
//  chatter
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.chatterPrimary.opacity(0.1))
                    .frame(width: 84, height: 84)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.chatterPrimary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.chatterTitle)
                    .foregroundColor(.chatterText)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.chatterBody)
                    .foregroundColor(.chatterSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.chatterHeadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.chatterGradient)
                        .clipShape(Capsule())
                        .shadow(color: Color.chatterPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "bubble.left.and.exclamationmark.bubble.right",
        title: "No Posts Yet",
        description: "Be the first to share something with the world!",
        buttonTitle: "Create Post"
    ) {}
}

