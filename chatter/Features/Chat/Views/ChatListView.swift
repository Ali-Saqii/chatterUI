//
//  ChatListView.swift
//  chatter
//

import SwiftUI

struct ChatListView: View {
    var body: some View {
        ZStack {
            Color.chatterBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                Image("chat_coming_soon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 340, maxHeight: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.chatterPrimary.opacity(0.3), radius: 24, x: 0, y: 12)
                    .padding(.horizontal, 24)
                
                Text("Real-time messaging is on its way.")
                    .font(.chatterSubheadline)
                    .foregroundColor(.chatterSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Chat Coming Soon") {
    NavigationStack {
        ChatListView()
    }
}
