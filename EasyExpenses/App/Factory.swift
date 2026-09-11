//
//  Factory.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 11/09/2026.
//

import Foundation
import SwiftData

protocol ComponentFactory {
    func createTransactionRepository() -> TransactionRepository
    
    func createTransactionsViewModel() -> TransactionsViewModel
}

struct EasyExpensesFactory: ComponentFactory {
    
    let modelContainer: ModelContainer
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func createTransactionRepository() -> TransactionRepository {
        
        return SwiftDataTransactionRepository(context: ModelContext(modelContainer))
    }
    
    func createTransactionsViewModel() -> TransactionsViewModel {
       return TransactionsViewModel(repo: createTransactionRepository())
    }
}
