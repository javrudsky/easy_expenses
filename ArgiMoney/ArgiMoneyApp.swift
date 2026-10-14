//
//  EasyExpensesApp.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import SwiftUI
import SwiftData

@main
struct ArgiMoneyApp: App {

    @StateObject private var themeManager = ThemeManager.shared
    private let factory: AppFactory? = try? DefaultAppFactory()
    
    init() {
        
        if let factory = self.factory {
            themeManager.setTheme(factory.appValues().theme())
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let factory = self.factory {
                AppRootView(appFactory: factory)
                    .environment(\.theme, themeManager.currentTheme)
            } else {
                // Fallback in case factory initialization fails
                SomethingHappenView()
            }
        }
    }
}

