//
//  OfflineBannerView.swift
//  chatter
//

import SwiftUI

struct OfflineBannerView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 13, weight: .bold))
                
                Text("Offline Mode — Showing Cached Content")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.95), Color.red.opacity(0.90)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
            )
            .padding(.horizontal, 16)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: networkMonitor.isConnected)
        }
    }
}

#Preview {
    OfflineBannerView()
}
