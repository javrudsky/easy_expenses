import Foundation
import SwiftUI
import Combine

@MainActor
protocol AudioRecordingViewModel: ObservableObject {
    var isRecording: Bool { get }
    var latestText: String { get }
    var isFinal: Bool { get }
    var pendingTransaction: Transaction? { get }
    var showTransactionForm: Bool { get set }
    var categories: [Category] { get }
    var accounts: [Account] { get }
    
    func startRecording()
    func stopRecording()
    func cancelRecording()
    func insertTransaction(builder: TransactionBuilder) async throws
    func reloadCategories() async
    func reloadAccounts() async
    func gridCategories(categories: [Category], selected: Category?) -> [Category]
}

@MainActor
final class DefaultAudioRecordingViewModel: AudioRecordingViewModel {
    @Published private(set) var isError: Bool = false
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var latestText: String = ""
    @Published private(set) var isFinal: Bool = false
    @Published private(set) var pendingTransaction: Transaction? = nil
    @Published var showTransactionForm: Bool = false
    
    @Published private(set) var categories: [Category] = []
    @Published private(set) var accounts: [Account] = []

    private let transcriber: AudioTranscriber
    private let inputParser: InputParser
    private let transactionRepo: TransactionRepository
    private let formService: TransactionFormViewService
    private var task: Task<Void, Never>?
    private let appValues: AppValues

    init(analyzer: AudioTranscriber,
         inputParser: InputParser,
         formService: TransactionFormViewService,
         dataStore: DataStore,
         appValues: AppValues) {
        self.transcriber = analyzer
        self.inputParser = inputParser
        self.transactionRepo = dataStore.transactionRepo
        self.formService = formService
        self.appValues = appValues
        Task {
            await reloadCategories()
            await reloadCategories()
        }
    }
    
    func startRecording() {
        if isRecording { return }
        isRecording = true
        task = Task {
            do {
                let stream = try await transcriber.start()
                var latestText = ""
                for await result in stream {
                    latestText = result.text
                    self.isFinal = result.isFinal
                    print("Stream received final? \(result.isFinal)")
                    print("latest after \(latestText)")
                }
                // result.isFinal could never be true
                if latestText == "" {
                    throw AudioError.unexpected("No parsed text")
                }
                let tx = try await self.inputParser.buildTransactionFrom(text: latestText,
                                                                         categories: categories,
                                                                         accounts: accounts,
                                                                         defaults: appValues.transactionDefaults())
                self.pendingTransaction = tx
                self.showTransactionForm = true
                self.isError = false
            } catch {
                // Handle error (permissions, unavailable, etc.)
                self.latestText = "Error: \(error.localizedDescription)"
                print("An error analyzing audio has occurred \(error)")
                self.pendingTransaction = nil
                self.showTransactionForm = false
                self.isError = true
            }
        }
    }
        
    func stopRecording() {
        Task {
            await transcriber.stop()
            isRecording = false
        }
    }

    func cancelRecording() {
        Task {
            await transcriber.stop()
            isRecording = false
            latestText = ""
            isFinal = false
            pendingTransaction = nil
            showTransactionForm = false
            task?.cancel()
            task = nil
        }
    }
    
    func insertTransaction(builder: TransactionBuilder) async throws {
        try await transactionRepo.insertOrUpdate(builder.build())
    }
    
    func reloadCategories() async {
            let items = await formService.getCategories()
            await MainActor.run {
                self.categories = items
            }
    }
    
    func reloadAccounts() async {
        let items = await formService.getAccounts()
        await MainActor.run {
            self.accounts = items
        }
    }
    
    func gridCategories(categories: [Category], selected: Category?) -> [Category] {
        formService.gridCategories(categories: categories, selected: selected)
    }
}
