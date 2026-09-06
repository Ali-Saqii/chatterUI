//
//  PrimaryButton.swift
//  chatter
//

import SwiftUI

enum ButtonStyleType {
    case primary
    case secondary
    case destructive
    case outline
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyleType = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var height: CGFloat = 50
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.chatterHeadline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .foregroundColor(textColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(borderOverlay)
            .opacity(isDisabled ? 0.6 : 1.0)
            .contentShape(Rectangle())
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .chatterPrimary
        case .destructive:
            return .white
        case .outline:
            return .chatterText
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.chatterGradient
        case .secondary:
            Color.chatterPrimary.opacity(0.12)
        case .destructive:
            Color.chatterDestructive
        case .outline:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if style == .outline {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.chatterBorder, lineWidth: 1.5)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
