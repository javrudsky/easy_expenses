//
//  MoreView.swift
//  ArgiMoneyPremium
//
//  Created by Javier Avrudsky on 09/11/2026.
//

import Foundation
import SwiftUI

struct MoreView: View {
    let af: AppFactory
    let vf: AppViewFactory
    let dataStore: DataStore

    init(appFactory: AppFactory,
         viewFactory: AppViewFactory,
         dataStore: DataStore) {
        self.af = appFactory
        self.vf = viewFactory
        self.dataStore = dataStore
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Management") {
                    NavigationLink { createDataManagementView() } label: { Label("Data Management", systemImage: "square.grid.2x2") }
                    NavigationLink {
                        PremiumGate(feature: .categoryManagement) {
                            vf.createExpenseCategoriesView(dataStore: dataStore)
                        } locked: {
                            lockedFeature(.categoryManagement,
                                          title: "Expense Categories",
                                          summary: "Customize expense categories with your own names, symbols and colors.",
                                          symbol: "square.grid.2x2")
                        }
                    } label: { Label("Expense Categories", systemImage: "square.grid.2x2") }
                    NavigationLink {
                        PremiumGate(feature: .categoryManagement) {
                            vf.createIncomeCategoriesView(dataStore: dataStore)
                        } locked: {
                            lockedFeature(.categoryManagement,
                                          title: "Income Categories",
                                          summary: "Customize income categories with your own names, symbols and colors.",
                                          symbol: "square.grid.2x2")
                        }
                    } label: { Label("Income Categories", systemImage: "square.grid.2x2") }
                    NavigationLink {
                        PremiumGate(feature: .accountCustomization) {
                            vf.createAccountsView(dataStore: dataStore)
                        } locked: {
                            lockedFeature(.accountCustomization,
                                          title: "Accounts",
                                          summary: "Manage multiple accounts with custom names, symbols and colors.",
                                          symbol: "creditcard")
                        }
                    } label: { Label("Accounts", systemImage: "creditcard") }
                }
                Section("Insights") {
                    NavigationLink { createReportsView() } label: { Label("Reports", systemImage: "chart.bar") }
                }
                Section("Premium") {
                    NavigationLink { PremiumStoreView() } label: { Label("Premium & Purchases", systemImage: "crown.fill") }
                }
            }
            .navigationTitle("More")
        }
    }
    
    private func createDataManagementView() -> DataManagementView {
        return DataManagementView(factory: af, dataStore: dataStore)
    }
    
    private func createReportsView() -> ReportsView<DefaultReportsViewModel> {
        return ReportsView<DefaultReportsViewModel>(dataStore: dataStore,
                                                    embedInNavigationStack: false)
    }

    private func lockedFeature(_ feature: PremiumFeature,
                               title: String,
                               summary: String,
                               symbol: String) -> some View {
        PremiumFeaturePreview(feature: feature, title: title, summary: summary) {
            Image(systemName: symbol)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
        }
    }
}
