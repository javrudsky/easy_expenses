//
//  Factory.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 11/09/2026.
//

import Foundation
import SwiftData
import AVFoundation

protocol AppFactory {
    
    static func createModelContainer(inMemory: Bool) throws -> ModelContainer
    func createTransactionRepository() -> TransactionRepository
    func createCategoryRepository() -> CategoryRepository
    func createAccountRepository() -> AccountRepository
    func createAudioTranscriber() -> AudioTranscriber
    func createInputParser() -> InputParser
    
    
    func dataStore() -> DataStore
    func appValues() -> AppValues
    
    // MARK: - Main actor declarations
    @MainActor func audioRecordingViewModel(dataStore: DataStore) -> any AudioRecordingViewModel
    @MainActor func transactionsViewModel(dataStore: DataStore) -> any TransactionsViewModel
    @MainActor func categoriesViewModel(transactionType: TransactionType,
                                        dataStore: DataStore) -> any CategoriesViewModel
    @MainActor func accountsViewModel(dataStore: DataStore) -> any AccountsViewModel
    @MainActor func transactionFormService(dataStore: DataStore) -> TransactionFormViewService
}

struct DefaultAppFactory: AppFactory {
    
    
    let modelContainer: ModelContainer
    init(modelContainer: ModelContainer? = nil,
         inMemory: Bool = false) throws {
        if let mc = modelContainer {
            self.modelContainer = mc
        } else {
            self.modelContainer = try Self.createModelContainer(inMemory: inMemory)
        }
    }
    
    // Visible for testing
    static func createModelContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            TransactionModel.self,
            CategoryModel.self,
            AccountModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
   
    func createTransactionRepository() -> TransactionRepository {
        // Create a SwiftData-backed Database from the ModelContext
        return SwiftDataTransactionRepository(modelContainer: modelContainer,
                                              transactionMapper: DefaultTransactionMapper())
    }
    
    func createCategoryRepository() -> CategoryRepository {
        return SwiftDataCategoryRepository(modelContainer: modelContainer)
    }
    
    func createAccountRepository() -> AccountRepository {
        return SwiftDataAccountRepository(modelContainer: modelContainer)
    }
    
    func dataStore() -> DataStore {
        DataStore(
            transactionRepo: createTransactionRepository(),
            categoryRepo: createCategoryRepository(),
            accountRepo: createAccountRepository()
        )
    }
        
    func createAudioTranscriber() -> AudioTranscriber {
        return DictationSpeechTranscriber()
    }

    func createInputParser() -> InputParser {
        //return DummyInputParser()
        return LLMParser()
    }
    
    func appValues() -> AppValues {
        return DefaultAppValues(valueStore: DefaultValueStore())
    }
    
    // MARK: - Main Actor definitions
    @MainActor
    func transactionsViewModel(dataStore: DataStore) -> any TransactionsViewModel {
        return DefaultTransactionsViewModel(formService: DefaultTransactionFormViewService(dataStore: dataStore),
                                            dataStore: dataStore)
    }
    
    @MainActor func audioRecordingViewModel(dataStore: DataStore) -> any AudioRecordingViewModel {
        return DefaultAudioRecordingViewModel(analyzer: createAudioTranscriber(),
                                              inputParser: createInputParser(),
                                              formService: DefaultTransactionFormViewService(dataStore: dataStore),
                                              dataStore: dataStore,
                                              appValues: appValues())
    }
    
    @MainActor
    func categoriesViewModel(transactionType: TransactionType,
                                   dataStore: DataStore) -> any CategoriesViewModel {
        return DefaultCategoriesViewModel(transactionType: transactionType,
                                          repo: dataStore.categoryRepo)
    }
    
    @MainActor
    func accountsViewModel(dataStore: DataStore) -> any AccountsViewModel {
        return DefaultAccountsViewModel(repo: dataStore.accountRepo)
    }
    
    @MainActor
    func transactionFormService(dataStore: DataStore) -> TransactionFormViewService {
        return DefaultTransactionFormViewService(dataStore: dataStore)
    }
}
