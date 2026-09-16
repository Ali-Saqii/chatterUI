//
//  ErrorBanner.swift
//  chatter
//

import SwiftUI

enum BannerType {
    case error
    case success
    case info
    
    var backgroundColor: Color {
        switch self {
        case .error:
            return Color.chatterDestructive
        case .success:
            return Color.chatterSuccess
        case .info:
            return Color.chatterPrimary
        }
    }
    
    var iconName: String {
        switch self {
        case .error:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct BannerData: Equatable {
    let message: String
    let type: BannerType
    
    static func == (lhs: BannerData, rhs: BannerData) -> Bool {
        lhs.message == rhs.message && lhs.type == rhs.type
    }
}

struct ErrorBanner: View {
    let banner: BannerData
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: banner.type.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(banner.message)
                .font(.chatterSubheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(banner.type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview("Banners") {
    VStack(spacing: 16) {
        ErrorBanner(banner: BannerData(message: "Failed to load posts. Please check connection.", type: .error)) {}
        ErrorBanner(banner: BannerData(message: "Profile updated successfully!", type: .success)) {}
        ErrorBanner(banner: BannerData(message: "Logged out successfully.", type: .info)) {}
    }
    .padding(.vertical)
}

