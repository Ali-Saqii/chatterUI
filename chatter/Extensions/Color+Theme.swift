//
//  Color+Theme.swift
//  chatter
//

import SwiftUI

extension Color {
    // Semantic brand colors
    static let chatterPrimary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.42, blue: 0.98, alpha: 1.0)
            : UIColor(red: 0.35, green: 0.32, blue: 0.92, alpha: 1.0)
    })
    
    static let chatterSecondary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.35, blue: 0.55, alpha: 1.0)
            : UIColor(red: 0.90, green: 0.25, blue: 0.48, alpha: 1.0)
    })
    
    static let chatterGradient = LinearGradient(
        gradient: Gradient(colors: [chatterPrimary, chatterSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Backgrounds
    static let chatterBackground = Color(uiColor: .systemGroupedBackground)
    static let chatterCardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let chatterInputBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    
    // Typography & Content
    static let chatterText = Color(uiColor: .label)
    static let chatterSubtext = Color(uiColor: .secondaryLabel)
    static let chatterTertiaryText = Color(uiColor: .tertiaryLabel)
    static let chatterBorder = Color(uiColor: .separator)
    
    // Semantic States
    static let chatterSuccess = Color(uiColor: .systemGreen)
    static let chatterWarning = Color(uiColor: .systemOrange)
    static let chatterDestructive = Color(uiColor: .systemRed)
}
