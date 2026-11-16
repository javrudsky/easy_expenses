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
    @State private var featureAccess: FeatureAccessManager

    init() {
        #if PREMIUM
        let service = StoreKitPurchaseService()
        #else
        let service = MockPurchaseService()
        #endif
        _featureAccess = State(initialValue: FeatureAccessManager(service: service))
    }
    
    var body: some Scene {
        WindowGroup {
            if let factory = self.factory {
                AppRootView(appFactory: factory)
                    .environment(\.theme, themeManager.currentTheme)
                    .environment(featureAccess)
                    .task {
                        await featureAccess.start()
                    }
            } else {
                // Fallback in case factory initialization fails
                SomethingHappenView()
            }
        }
    }
}

