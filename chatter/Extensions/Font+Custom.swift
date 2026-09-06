//
//  Font+Custom.swift
//  chatter
//

import SwiftUI

extension Font {
    static let chatterLargeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let chatterTitle = Font.system(.title2, design: .rounded).weight(.bold)
    static let chatterHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let chatterSubheadline = Font.system(.subheadline, design: .default).weight(.medium)
    static let chatterBody = Font.system(.body, design: .default)
    static let chatterCallout = Font.system(.callout, design: .default)
    static let chatterCaption = Font.system(.caption, design: .default)
    static let chatterCaptionBold = Font.system(.caption, design: .rounded).weight(.semibold)
}
