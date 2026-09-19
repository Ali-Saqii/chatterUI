//
//  DownloadToastView.swift
//  chatter
//

import SwiftUI

/// An animated toast that appears at the top of the screen to show download status.
struct DownloadToastView: View {
    let result: DownloadManager.DownloadResult?
    let isDownloading: Bool

    var body: some View {
        Group {
            if isDownloading {
                toastContent(
                    icon: "arrow.down.circle",
                    message: "Downloading...",
                    isLoading: true,
                    color: .chatterPrimary
                )
            } else if let result = result {
                switch result {
                case .success(let folder):
                    toastContent(
                        icon: "checkmark.circle.fill",
                        message: "Saved to \(folder)",
                        isLoading: false,
                        color: .chatterSuccess
                    )
                case .failure(let msg):
                    toastContent(
                        icon: "xmark.circle.fill",
                        message: msg,
                        isLoading: false,
                        color: .chatterDestructive
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func toastContent(
        icon: String,
        message: String,
        isLoading: Bool,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: color))
                    .scaleEffect(0.85)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(message)
                .font(.chatterCaptionBold)
                .foregroundColor(.chatterText)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.chatterCardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

/// A view modifier that overlays a download toast at the top of any view.
struct DownloadToastModifier: ViewModifier {
    @ObservedObject var downloadManager: DownloadManager
    @State private var showToast = false
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showToast {
                    DownloadToastView(
                        result: downloadManager.downloadResult,
                        isDownloading: downloadManager.isDownloading
                    )
                    .padding(.top, 8)
                    .zIndex(999)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showToast)
                }
            }
            .onChange(of: downloadManager.isDownloading) { _, downloading in
                if downloading {
                    showToast = true
                    dismissTask?.cancel()
                }
            }
            .onChange(of: downloadManager.downloadResult) { _, result in
                if result != nil {
                    showToast = true
                    dismissTask?.cancel()
                    dismissTask = Task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        if !Task.isCancelled {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    func downloadToast(manager: DownloadManager) -> some View {
        modifier(DownloadToastModifier(downloadManager: manager))
    }
}
