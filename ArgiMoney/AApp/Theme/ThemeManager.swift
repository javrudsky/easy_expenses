//
//  ThemeManager.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 08/10/2026.
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var currentTheme: Theme

    private init() {
        self.currentTheme = Theme(name: .default)
    }

    func setTheme(_ name: ThemeName) {
        guard name == currentTheme.name else { return }
        self.currentTheme = loadTheme(name: name)
    }
    
    private func loadTheme(name: ThemeName) -> Theme {
        switch name {
        default:
            return Theme(name: .default)
        }
    }
}

private struct ThemeKey: @MainActor EnvironmentKey {
    @MainActor static let defaultValue: Theme = Theme(name: .default)
}

@MainActor
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
