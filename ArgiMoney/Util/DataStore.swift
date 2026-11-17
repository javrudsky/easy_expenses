//
//  DataStore.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 28/09/2026.
//

import Foundation

struct DataStore {
    let transactionRepo: TransactionRepository
    let categoryRepo: CategoryRepository
    let accountRepo: AccountRepository
}
