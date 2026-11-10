//
//  ViewFactory.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 09/11/2026.
//

import Foundation
import SwiftUI

protocol AppViewFactory {
    @MainActor func createAccountsView(dataStore: DataStore) -> AccountsViewWrapper
    @MainActor func createIncomeCategoriesView(dataStore: DataStore) -> IncomeCategoriesViewWrapper
    @MainActor func createExpenseCategoriesView(dataStore: DataStore) -> ExpenseCategoriesViewWrapper

}
