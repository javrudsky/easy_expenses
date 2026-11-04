//
//  AppDefaults.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 28/09/2026.
//

import Foundation

struct AppDefaults {
    
    static let defaultCategoryColor = "0.0, 0.0, 0.0, 1.0"
    static let defaultCategoryImage = "wallet.bifold.fill"

    // Provide sensible defaults for first run
    static let incomeCategory: Category = Category(
        id: UUID(),
        name: "Salary", transactionType: .income,
        imageName: "dollarsign.circle.fill",
        rgbColor: defaultCategoryColor
    )

    static let expenseCategory: Category = Category(
        id: UUID(),
        name: "General",
        transactionType: .expense,
        imageName: defaultCategoryImage,
        rgbColor: defaultCategoryColor,
    )

    static let account: Account = Account(
        id: UUID(),
        name: "Cash"
    )
    
    static let theme: ThemeName = ThemeName(rawValue: "default")!
    

    static let defaultCategories = [
        // Expense categories
        
        Category(name: "Groceries", transactionType: .expense,
                 imageName: "cart.fill", rgbColor: defaultCategoryColor),
        Category(name: "Housing", transactionType: .expense,
                 imageName: "house.fill", rgbColor: defaultCategoryColor),
        Category(name: "Utilities", transactionType: .expense,
                 imageName: "bolt.fill", rgbColor: defaultCategoryColor),
        Category(name: "Transportation", transactionType: .expense,
                 imageName: "car.fill", rgbColor: defaultCategoryColor),
        Category(name: "Health", transactionType: .expense,
                 imageName: "heart.fill", rgbColor: defaultCategoryColor),
        Category(name: "Dining & Entertainment", transactionType: .expense,
                 imageName: "fork.knife", rgbColor: defaultCategoryColor),
        Category(name: "Shopping", transactionType: .expense,
                 imageName: "bag.fill", rgbColor: defaultCategoryColor),
        Category(name: "Subscriptions", transactionType: .expense,
                 imageName: "creditcard.fill", rgbColor: defaultCategoryColor),
        Category(name: "Education", transactionType: .expense,
                 imageName: "graduationcap.fill", rgbColor: defaultCategoryColor),
        Category(name: "Travel", transactionType: .expense,
                 imageName: "airplane", rgbColor: defaultCategoryColor),
        Category(name: "Taxes", transactionType: .expense,
                 imageName: "doc.text.fill", rgbColor: defaultCategoryColor),
        Self.expenseCategory,

        // Income categories
        Category(name: "Freelance", transactionType: .income,
                 imageName: "laptopcomputer", rgbColor: defaultCategoryColor),
        Category(name: "Business Income", transactionType: .income,
                 imageName: "building.2.fill", rgbColor: defaultCategoryColor),
        Category(name: "Investment Income", transactionType: .income,
                 imageName: "chart.line.uptrend.xyaxis", rgbColor: defaultCategoryColor),
        Self.incomeCategory
    ]
}

