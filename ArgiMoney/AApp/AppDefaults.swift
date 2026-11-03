//
//  AppDefaults.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 28/09/2026.
//

import Foundation

struct AppDefaults {
    
    static let defaultCategoryColor = "000000"
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
                 imageName: "cart.fill", rgbColor: "3485FF"),
        Category(name: "Housing", transactionType: .expense,
                 imageName: "house.fill", rgbColor: "9565E8"),
        Category(name: "Utilities", transactionType: .expense,
                 imageName: "bolt.fill", rgbColor: "FFC629"),
        Category(name: "Transportation", transactionType: .expense,
                 imageName: "car.fill", rgbColor: "3485FF"),
        Category(name: "Health", transactionType: .expense,
                 imageName: "heart.fill", rgbColor: "FF4B55"),
        Category(name: "Dining & Entertainment", transactionType: .expense,
                 imageName: "fork.knife", rgbColor: "FF9233"),
        Category(name: "Shopping", transactionType: .expense,
                 imageName: "bag.fill", rgbColor: "F04498"),
        Category(name: "Subscriptions", transactionType: .expense,
                 imageName: "creditcard.fill", rgbColor: "2CC65C"),
        Category(name: "Education", transactionType: .expense,
                 imageName: "graduationcap.fill", rgbColor: "6478D8"),
        Category(name: "Travel", transactionType: .expense,
                 imageName: "airplane", rgbColor: "9565E8"),
        Category(name: "Taxes", transactionType: .expense,
                 imageName: "doc.text.fill", rgbColor: "78879B"),
        Self.expenseCategory,

        // Income categories
        Category(name: "Freelance", transactionType: .income,
                 imageName: "laptopcomputer", rgbColor: "3485FF"),
        Category(name: "Business Income", transactionType: .income,
                 imageName: "building.2.fill", rgbColor: "9565E8"),
        Category(name: "Investment Income", transactionType: .income,
                 imageName: "chart.line.uptrend.xyaxis", rgbColor: "18A88F"),
        Self.incomeCategory
    ]
}

