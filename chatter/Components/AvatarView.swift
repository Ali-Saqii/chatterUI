//
//  AvatarView.swift
//  chatter
//

import SwiftUI

struct AvatarView: View {
    let urlString: String?
    let name: String
    var size: CGFloat = 44
    var showBorder: Bool = false
    var borderColor: Color = .chatterPrimary
    
    private var initials: String {
        let components = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let second = components[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let single = components.first, !single.isEmpty {
            return String(single.prefix(2)).uppercased()
        }
        return "C"
    }
    
    private var resolvedURL: URL? {
        guard let urlString = urlString, !urlString.isEmpty else { return nil }
        if urlString.hasPrefix("http") {
            return URL(string: urlString)
        }
        // If relative path from backend
        var base = APIClient.shared.baseURL
        if base.hasSuffix("/api/") {
            base = String(base.dropLast(5))
        } else if base.hasSuffix("/api") {
            base = String(base.dropLast(4))
        }
        let full = base.hasSuffix("/") ? "\(base)\(urlString)" : "\(base)/\(urlString)"
        return URL(string: full)
    }
    
    var body: some View {
        Group {
            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            placeholderBackground
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(showBorder ? borderColor : Color.chatterBorder.opacity(0.4), lineWidth: showBorder ? 2 : 1)
        )
    }
    
    private var placeholderBackground: some View {
        LinearGradient(
            colors: [Color.chatterPrimary.opacity(0.8), Color.chatterSecondary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var placeholderView: some View {
        ZStack {
            placeholderBackground
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
