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
                    NavigationLink { createDataManagementView() } label: { Label("Import/Export", systemImage: "square.grid.2x2") }
                    NavigationLink { vf.createExpenseCategoriesView(dataStore: dataStore) } label: { Label("Expense Categories", systemImage: "square.grid.2x2") }
                    NavigationLink { vf.createIncomeCategoriesView(dataStore: dataStore) } label: { Label("Income Categories", systemImage: "square.grid.2x2") }
                    NavigationLink { vf.createAccountsView(dataStore: dataStore) } label: { Label("Accounts", systemImage: "creditcard") }
                }
                Section("Insights") {
                    NavigationLink { ReportsView() } label: { Label("Reports", systemImage: "chart.bar") }
                }
            }
            .navigationTitle("More")
        }
    }
    
    private func createDataManagementView() -> DataManagementView {
        return DataManagementView(factory: af, dataStore: dataStore)
    }
}
