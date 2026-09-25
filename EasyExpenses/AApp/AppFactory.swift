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
    
    // MARK: - Main actor declarations
    @MainActor func createAudioRecordingViewModel(repo: TransactionRepository) -> any AudioRecordingViewModel
    @MainActor func createTransactionsViewModel(repo: TransactionRepository) -> any TransactionsViewModel
    @MainActor func createCategoriesViewModel() -> any CategoriesViewModel
    @MainActor func createAccountsViewModel() -> any AccountsViewModel
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
        
    func createAudioTranscriber() -> AudioTranscriber {
        return DictationSpeechTranscriber()
    }

    func createInputParser() -> InputParser {
        //return DummyInputParser()
        return LLMParser()
    }
    
    // MARK: - Main Actor definitions
    @MainActor
    func createTransactionsViewModel(repo: TransactionRepository) -> any TransactionsViewModel {
        return DefaultTransactionsViewModel(repo: repo)
    }
    
    @MainActor func createAudioRecordingViewModel(repo: TransactionRepository) -> any AudioRecordingViewModel {
        return DefaultAudioRecordingViewModel(analyzer: createAudioTranscriber(),
                                              inputParser: createInputParser(),
                                              transactionRepo: repo)
    }
    
    @MainActor
    func createCategoriesViewModel() -> any CategoriesViewModel {
        return DefaultCategoriesViewModel(repo: createCategoryRepository())
    }
    
    @MainActor
    func createAccountsViewModel() -> any AccountsViewModel {
        return DefaultAccountsViewModel(repo: createAccountRepository())
    }
}

