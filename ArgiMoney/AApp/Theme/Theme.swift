//
//  Theme.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 08/10/2026.
//

import SwiftUI
import Foundation

enum ThemeName: String, CaseIterable, Identifiable {
    case `default`
    var id: String { rawValue }
}

struct Theme {
    private(set) var name: ThemeName = .default
    var brandPrimary: Color
    var brandSecondary: Color

    // MARK: - Backgrounds
    var backgroundPrimary: Color
    var backgroundSecondary: Color

    // MARK: - Text
    var textPrimary: Color
    var textSecondary: Color

    // MARK: - Accents / Status
    var accentPositive: Color
    var accentNegative: Color
    var accentLightPositive: Color
    var accentLightNegative: Color

    // MARK: - Components
    var micIdleBackground: Color
    var micRecordingBackground: Color
    var cardBackground: Color
    
    // MARK: - Form
    var inputFieldBorder: Color

    init(name: ThemeName) {
        self.name = name
        // MARK: - Brand
        brandPrimary = Theme.color("BrandPrimary", .accentColor, name)
        brandSecondary = Theme.color("SecondaryPrimary", Color.blue, name)

        // MARK: - Backgrounds
        backgroundPrimary = Theme.color("BgPrimary", .systemBackground, name)
        backgroundSecondary = Theme.color("BgSecondary", .secondarySystemBackground, name)

        // MARK: - Text
        textPrimary = Theme.color("TextPrimary", .primary, name)
        textSecondary = Theme.color("TextSecondary", .secondary, name)

        // MARK: - Accents / Status
        accentPositive = Theme.color("AccentPositive", Color.green)
        accentNegative = Theme.color("AccentNegative", Color.red)
        
        accentLightPositive = Theme.color("AccentLightPositive", Color.green)
        accentLightNegative = Theme.color("AccentLightNegative", Color.red)

        micIdleBackground = Theme.color("MicIdleBg", .blue.opacity(0.15))
        micRecordingBackground = Theme.color("MicRecordingBg", .red.opacity(0.20))
        cardBackground = Theme.color("CardBg", .secondarySystemBackground)
        
        inputFieldBorder = Theme.color("InputFieldBorder", Color.gray, name)
    }
    
    private static func color(_ colorName: String, _ fallback: UIColor, _ theme: ThemeName = ThemeName.default) -> Color {
        return color(colorName, Color(fallback), theme)
    }
    
    private static func color(_ colorName: String, _ fallback: Color, _ theme: ThemeName = ThemeName.default) -> Color {
        let prefix = theme.rawValue
        let fullName = "\(prefix)_\(colorName)"
        if UIColor(named: fullName) != nil {
            return Color(fullName)
        }
        return fallback
    }
}
