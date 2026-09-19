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
    var allowsFullScreen: Bool = false
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isFullScreen = false
    @StateObject private var downloadManager = DownloadManager()
    
    private var resolvedURL: URL? {
        URLResolver.resolve(mediaURL)
    }
    
    var body: some View {
        Group {
            if mediaType == .image {
                imageView
            } else if mediaType == .video {
                videoView
            }
        }
        .downloadToast(manager: downloadManager)
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
                    if allowsFullScreen {
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
                            .overlay(alignment: .bottomTrailing) {
                                downloadButton(mediaType: .image)
                            }
                    } else {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: maxHeight)
                            .background(Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                        .overlay(alignment: .bottomTrailing) {
                            if allowsFullScreen {
                                downloadButton(mediaType: .video)
                            }
                        }
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
                player = nil
            }
        }
    }
    
    // MARK: - Download Button Overlay
    
    @ViewBuilder
    private func downloadButton(mediaType: MediaType) -> some View {
        Button(action: {
            Task {
                await downloadManager.download(urlString: mediaURL, mediaType: mediaType)
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 38, height: 38)
                
                if downloadManager.isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.75)
                } else {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(downloadManager.isDownloading)
        .padding(10)
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

#Preview("Media Player") {
    VStack(spacing: 16) {
        MediaPlayerView(
            mediaURL: "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
            mediaType: .image
        )
    }
    .padding()
}

