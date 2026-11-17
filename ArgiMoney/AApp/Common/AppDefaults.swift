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

    static let defaultAccountColor = "0.29, 0.52, 1.0, 1.0"
    static let defaultAccountImage = "creditcard.fill"

    // Provide sensible defaults for first run
    static let incomeCategory: Category = Category(
        id: UUID(),
        name: String(localized: "Salary"), transactionType: .income,
        imageName: "dollarsign.circle.fill",
        rgbColor: defaultCategoryColor
    )

    static let expenseCategory: Category = Category(
        id: UUID(),
        name: String(localized: "General"),
        transactionType: .expense,
        imageName: defaultCategoryImage,
        rgbColor: defaultCategoryColor,
    )

    static let account: Account = Account(
        id: UUID(),
        name: String(localized: "Cash"),
        imageName: defaultAccountImage,
        rgbColor: defaultAccountColor
    )
    
    static let theme: ThemeName = ThemeName(rawValue: "default")!
    

    static let defaultCategories = [
        // Expense categories
        
        Category(name: String(localized: "Groceries"), transactionType: .expense,
                 imageName: "cart.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Housing"), transactionType: .expense,
                 imageName: "house.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Utilities"), transactionType: .expense,
                 imageName: "bolt.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Transportation"), transactionType: .expense,
                 imageName: "car.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Health"), transactionType: .expense,
                 imageName: "heart.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Dining & Entertainment"), transactionType: .expense,
                 imageName: "fork.knife", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Shopping"), transactionType: .expense,
                 imageName: "bag.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Subscriptions"), transactionType: .expense,
                 imageName: "creditcard.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Education"), transactionType: .expense,
                 imageName: "graduationcap.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Travel"), transactionType: .expense,
                 imageName: "airplane", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Taxes"), transactionType: .expense,
                 imageName: "doc.text.fill", rgbColor: defaultCategoryColor),
        Self.expenseCategory,

        // Income categories
        Category(name: String(localized: "Freelance"), transactionType: .income,
                 imageName: "laptopcomputer", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Business Income"), transactionType: .income,
                 imageName: "building.2.fill", rgbColor: defaultCategoryColor),
        Category(name: String(localized: "Investment Income"), transactionType: .income,
                 imageName: "chart.line.uptrend.xyaxis", rgbColor: defaultCategoryColor),
        Self.incomeCategory
    ]
}
