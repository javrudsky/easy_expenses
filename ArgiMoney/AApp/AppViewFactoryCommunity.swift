//
//  AccountsViewCommunity.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 09/11/2026.
//

import Foundation
import SwiftUI

struct AccountsViewWrapper: View {
    var body: some View {
        VStack {
            Text("Community view")
        }
    }
}

struct IncomeCategoriesViewWrapper: View {
    var body: some View {
        VStack {
            Text("Community view")
        }
    }
}

struct ExpenseCategoriesViewWrapper: View {
    var body: some View {
        VStack {
            Text("Community view")
        }
    }
}

struct DefaultViewFactory: AppViewFactory {
    @MainActor
    func createAccountsView(dataStore: DataStore) -> AccountsViewWrapper {
        return AccountsViewWrapper()
    }
    
    @MainActor
    func createIncomeCategoriesView(dataStore: DataStore) -> IncomeCategoriesViewWrapper {
        return IncomeCategoriesViewWrapper()
    }
    
    @MainActor
    func createExpenseCategoriesView(dataStore: DataStore) -> ExpenseCategoriesViewWrapper {
        return ExpenseCategoriesViewWrapper()
    }


}
