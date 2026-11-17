//
//  AccountsViewPremium.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 09/11/2026.
//

import Foundation
import SwiftUI

struct AccountsViewWrapper: View {
    let dataStore: DataStore
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    var body: some View {
        let vm = DefaultAccountsViewModel(repo: dataStore.accountRepo)
        return AccountsView(viewModel: vm)
    }
}

struct IncomeCategoriesViewWrapper: View {
    let dataStore: DataStore
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    var body: some View {
        let vm = DefaultCategoriesViewModel(transactionType: .income,
                                            repo: dataStore.categoryRepo)
        return CategoriesView(viewModel: vm)
    }
}

struct ExpenseCategoriesViewWrapper: View {
    let dataStore: DataStore
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    var body: some View {
        let vm = DefaultCategoriesViewModel(transactionType: .expense,
                                            repo: dataStore.categoryRepo)
        return CategoriesView(viewModel: vm)
    }
}


struct DefaultViewFactory: AppViewFactory {
    
    @MainActor
    func createAccountsView(dataStore: DataStore) -> AccountsViewWrapper {
        return AccountsViewWrapper(dataStore: dataStore)
    }
    
    @MainActor
    func createIncomeCategoriesView(dataStore: DataStore) -> IncomeCategoriesViewWrapper {
        return IncomeCategoriesViewWrapper(dataStore: dataStore)
    }
    
    @MainActor
    func createExpenseCategoriesView(dataStore: DataStore) -> ExpenseCategoriesViewWrapper {
        return ExpenseCategoriesViewWrapper(dataStore: dataStore)
    }

    
}
