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

    var body: some Scene {
        WindowGroup {
            if let factory = try? DefaultAppFactory() {
                AppRootView(appFactory: factory)
            } else {
                // Fallback in case factory initialization fails
                SomethingHappenView()
            }
        }
    }
}

