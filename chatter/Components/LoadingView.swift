//
//  LoadingView.swift
//  chatter
//

import SwiftUI

struct PostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.chatterSubtext.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.chatterSubtext.opacity(0.18))
                        .frame(width: 130, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.chatterSubtext.opacity(0.12))
                        .frame(width: 80, height: 10)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.15))
                    .frame(width: 220, height: 12)
            }
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.chatterSubtext.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            
            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.12))
                    .frame(width: 50, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.12))
                    .frame(width: 50, height: 16)
                Spacer()
            }
        }
        .chatterCard()
        .shimmering()
    }
}

struct UserSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.chatterSubtext.opacity(0.15))
                .frame(width: 46, height: 46)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.18))
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chatterSubtext.opacity(0.12))
                    .frame(width: 90, height: 10)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.chatterSubtext.opacity(0.15))
                .frame(width: 90, height: 34)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .shimmering()
    }
}

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.chatterPrimary))
            
            Text(message)
                .font(.chatterSubheadline)
                .foregroundColor(.chatterSubtext)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.chatterBackground.opacity(0.7))
    }
}
