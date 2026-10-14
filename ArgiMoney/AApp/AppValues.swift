//
//  AppValues.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 02/10/2026.
//

import Foundation
protocol AppValues: Sendable {
    func getAndUpdateIsFirstRun() -> Bool
    func set(incomeCategory: Category)
    func incomeCategory() -> Category
    func set(expenseCategory: Category)
    func expenseCategory() -> Category
    func set(account: Account)
    func account() -> Account
    func transactionDefaults() -> TransactionDefaults
    
    func theme() -> ThemeName
    func set(theme: ThemeName)
}

struct DefaultAppValues: AppValues {
    
    struct Key {
        static let isFirstRun = "isFirstRun"
        static let incomeCategory = "incomeCategory"
        static let expenseCategory = "expenseCategory"
        static let account = "account"
        static let theme = "theme"
    }
    
    let vs: ValueStore
    
    init(valueStore: ValueStore) {
        self.vs = valueStore
    }
    
    func getAndUpdateIsFirstRun() -> Bool {
        let val = vs.getBool(forKey: Key.isFirstRun, default: true)
        if val {
            vs.setBool(false, forKey: Key.isFirstRun)
        }
        return val
    }

    func set(incomeCategory c: Category) {
        setCategory(c)
    }
    
    func set(expenseCategory c: Category) {
        setCategory(c)
    }

    // MARK: - Category
    private func setCategory(_ category: Category) {
        let key = category.transactionType == .income ? Key.incomeCategory : Key.expenseCategory
        do {
            let data = try JSONEncoder().encode(category)
            if let json = String(data: data, encoding: .utf8) {
                vs.setString(json, forKey: key)
            } else {
                throw ParserError.onParsing("Could not parse default category")
            }
        } catch {
            print("Unknown error with category: \(error)")
        }
    }
    
    func incomeCategory() -> Category {
        return category(key: Key.incomeCategory) ?? AppDefaults.incomeCategory
    }
    
    func expenseCategory() -> Category {
        return category(key: Key.expenseCategory) ?? AppDefaults.expenseCategory
    }

    private func category(key: String) -> Category? {
        let json = vs.getString(forKey: key, default: "")
        if let data = json?.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(Category.self, from: data) {
                return decoded
            }
        }
        return nil
    }

    // MARK: - Account
    func set(account: Account) {
        do {
            let data = try JSONEncoder().encode(account)
            if let json = String(data: data, encoding: .utf8) {
                vs.setString(json, forKey: Key.account)
            } else {
                throw ParserError.onParsing("Could not parse default account")
            }
        } catch {
            print("Unknown error: \(error)")
        }
    }

    func account() -> Account {
        let json = vs.getString(forKey: Key.account, default: nil)
        if let data = json?.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(Account.self, from: data) {
                return decoded
            }
            print("Could not get default account")
            return AppDefaults.account
        }
        // No stored value at all, return default
        return AppDefaults.account
    }
    
    func transactionDefaults() -> TransactionDefaults {
        // TODO: Add a refresh check
        return TransactionDefaults(date: Date().timeIntervalSince1970,
                                   incomeCategory: incomeCategory(),
                                   expenseCategory: expenseCategory(),
                                   account: account())
    }

    // MARK: -- Theme
    func set(theme name: ThemeName) {
        vs.setString(name.rawValue, forKey: Key.theme)
    }
    
    func theme() -> ThemeName {
        let nameStr = vs.getString(forKey: Key.theme,
                                   default: nil) ?? AppDefaults.theme.rawValue
        return ThemeName(rawValue: nameStr) ?? AppDefaults.theme
    }
}
