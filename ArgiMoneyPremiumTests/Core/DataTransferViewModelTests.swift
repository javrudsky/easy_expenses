import Foundation
import Testing
@testable import ArgiMoneyPremium

@Suite("Import and export view model tests")
struct DataTransferViewModelTests {
    private func summary() -> ImportSummary {
        let category = Category(name: "Food", transactionType: .expense, imageName: "fork.knife", rgbColor: "#FF0000")
        let account = Account(name: "Cash", imageName: "creditcard.fill", rgbColor: "0.29, 0.52, 1.0, 1.0")
        let transaction = Transaction(
            id: UUID(),
            date: 1,
            category: category,
            detail: "Lunch",
            transactionType: .expense,
            account: account,
            amount: 10
        )
        return ImportSummary(
            logSummary: ImportLogSummary(lines: []),
            categories: [category],
            duplicatedTransactions: [],
            accounts: [account],
            transactions: [transaction]
        )
    }

    @MainActor
    @Test
    func exportViewModelWritesTheServiceCsvToATemporaryFile() async throws {
        let expectedCSV = "transaction_id,date\n1,2026-10-21T00:00:00Z"
        let service = StubDataTransferService(exportedCSV: expectedCSV, importSummary: summary())
        let viewModel = DefaultExportTransactionsViewModel(dataTransferService: service)
        viewModel.selectedRange = .all

        await viewModel.exportToCsv()

        guard let url = viewModel.exportURL else {
            Issue.record("Expected export to produce a temporary file URL")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }
        let writtenCSV = try String(contentsOf: url, encoding: .utf8)
        #expect(writtenCSV == expectedCSV)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isExporting)
    }

    @MainActor
    @Test
    func importViewModelLoadsLocalFileExecutesSummaryAndResetsState() async throws {
        let expectedSummary = summary()
        let service = StubDataTransferService(exportedCSV: "", importSummary: expectedSummary)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("import-view-model-\(UUID().uuidString).csv")
        try "csv content".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let viewModel = DefaultImportTransactionsViewModel(dataTransferService: service, selectedFile: fileURL)

        let importedSummary = try await viewModel.importCsv()
        #expect(importedSummary.transactions.count == 1)
        #expect(viewModel.summary?.transactions.count == 1)
        #expect(viewModel.areIssues)
        #expect(!viewModel.isImporting)

        try await viewModel.proceedImport()

        let executionCount = await service.executionCount
        #expect(executionCount == 1)
        #expect(viewModel.selectedFile == nil)
        #expect(viewModel.summary == nil)
        #expect(viewModel.lastError == nil)
    }

    @MainActor
    @Test
    func importViewModelCancelResetsTheSelectedFileAndSummary() {
        let service = StubDataTransferService(exportedCSV: "", importSummary: summary())
        let viewModel = DefaultImportTransactionsViewModel(
            dataTransferService: service,
            selectedFile: URL(fileURLWithPath: "/tmp/import.csv")
        )

        viewModel.cancelImport()

        #expect(viewModel.selectedFile == nil)
        #expect(viewModel.summary == nil)
        #expect(viewModel.lastError == nil)
        #expect(!viewModel.isImporting)
    }
}
