//
//  AppDefaults.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 28/09/2026.
//

import Foundation

struct AppDefaults {
    // Provide sensible defaults for first run
    static let incomeCategory: Category = Category(
        id: UUID(),
        name: "Salary",
        transactionType: .income
    )

    static let expenseCategory: Category = Category(
        id: UUID(),
        name: "General",
        transactionType: .expense
    )

    static let account: Account = Account(
        id: UUID(),
        name: "Cash"
    )
    
    static let theme: ThemeName = ThemeName(rawValue: "default")!
    
    static let defaultCategories = [
        // Expense categories
        Category(name: "Groceries", transactionType: .expense),
        Category(name: "Housing", transactionType: .expense),
        Category(name: "Utilities", transactionType: .expense),
        Category(name: "Transportation", transactionType: .expense),
        Category(name: "Health", transactionType: .expense),
        Category(name: "Dining & Entertainment", transactionType: .expense),
        Category(name: "Shopping", transactionType: .expense),
        Category(name: "Subscriptions", transactionType: .expense),
        Category(name: "Education", transactionType: .expense),
        Category(name: "Travel", transactionType: .expense),
        Category(name: "Taxes", transactionType: .expense),
        Self.expenseCategory,

        // Income categories
        Category(name: "Salary", transactionType: .income),
        Category(name: "Freelance", transactionType: .income),
        Category(name: "Business Income", transactionType: .income),
        Category(name: "Investment Income", transactionType: .income),
        Self.incomeCategory
    ]
}

