//
//  MediaPlayerView.swift
//  chatter
//

import SwiftUI
import AVKit

struct MediaPlayerView: View {
    let mediaURL: String?
    let mediaType: MediaType
    var maxHeight: CGFloat = 340
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isFullScreen = false
    
    private var resolvedURL: URL? {
        guard let mediaURL = mediaURL, !mediaURL.isEmpty else { return nil }
        if mediaURL.hasPrefix("http") {
            return URL(string: mediaURL)
        }
        var base = APIClient.shared.baseURL
        if base.hasSuffix("/api/") {
            base = String(base.dropLast(5))
        } else if base.hasSuffix("/api") {
            base = String(base.dropLast(4))
        }
        let full = base.hasSuffix("/") ? "\(base)\(mediaURL)" : "\(base)/\(mediaURL)"
        return URL(string: full)
    }
    
    var body: some View {
        Group {
            if mediaType == .image {
                imageView
            } else if mediaType == .video {
                videoView
            }
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        if let url = resolvedURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.chatterInputBackground
                        ProgressView()
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: maxHeight)
                        .background(Color.black.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .onTapGesture {
                            isFullScreen = true
                        }
                        .sheet(isPresented: $isFullScreen) {
                            FullScreenImageView(image: image)
                        }
                case .failure:
                    ZStack {
                        Color.chatterInputBackground
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 28))
                                .foregroundColor(.chatterSubtext)
                            Text("Unable to load image")
                                .font(.chatterCaption)
                                .foregroundColor(.chatterSubtext)
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private var videoView: some View {
        if let url = resolvedURL {
            ZStack {
                if let p = player {
                    VideoPlayer(player: p)
                        .frame(height: maxHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    ZStack {
                        Color.black.opacity(0.8)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .onAppear {
                if player == nil {
                    let avPlayer = AVPlayer(url: url)
                    self.player = avPlayer
                }
            }
            .onDisappear {
                player?.pause()
            }
        }
    }
}

struct FullScreenImageView: View {
    let image: Image
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(20)
            }
        }
    }
}
