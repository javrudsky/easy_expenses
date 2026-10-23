import Foundation
import SwiftUI
import Combine

@MainActor
protocol ImportTransactionsViewModel: ObservableObject {
    var selectedFile: URL? { get }
    var isImporting: Bool { get }

    var summary: ImportSummary? { get }
    var areIssues: Bool { get }

    var lastError: String? { get set }
    
    func setSelectedFile(_ url: URL?)
    func importCsv() async throws  -> ImportSummary
    func proceedImport() async throws
    func cancelImport()
}

@MainActor
final class DefaultImportTransactionsViewModel: ImportTransactionsViewModel {

    @Published var selectedFile: URL?
    @Published var isImporting: Bool
    @Published var lastError: String?

    @Published private(set) var summary: ImportSummary? = nil

    private let dataTransferService: DataTransferService
    private let fileUtil = FileUtil()

    var areIssues: Bool {
        summary != nil && (summary?.logSummary.errorCount ?? 0) == 0
    }

    init(dataTransferService: DataTransferService, selectedFile: URL? = nil) {
        self.dataTransferService = dataTransferService
        self.selectedFile = selectedFile
        self.isImporting = false
        self.lastError = nil
    }

    func setSelectedFile(_ url: URL?) {
        self.selectedFile = url
        self.lastError = nil
    }

    func importCsv() async throws -> ImportSummary {
        guard let fileUrl = selectedFile else {
            lastError = "Invalid file URL"
            throw DataTransferError.wrongFile("Could not open file")
        }
        
        if !fileUrl.startAccessingSecurityScopedResource() {
            print("Permission denied")
            throw DataTransferError.permissionDenied("Could not open file")
        }

        isImporting = true
        defer { isImporting = false }

        do {
            let content = try fileUtil.open(fileUrl)
            fileUrl.stopAccessingSecurityScopedResource()
            let summary = try await dataTransferService.importFrom(csv: content, logBuilder: DefaultImportLogBuilder())
            self.summary = summary
            print(summary.logSummary.log)
            return summary
        } catch {
            self.lastError = (error as NSError).localizedDescription
            self.summary = nil
            throw error
        }
    }

    func proceedImport() async throws {
       
        guard let summary = self.summary else { return }
        
        do {
            try await dataTransferService.executeImport(summary: summary)
            resetProcess()
        } catch {
            throw DataTransferError.importFail("Something when wrong importing")
        }
    }

    func cancelImport() {
        // Placeholder implementation; reset state if needed
    }
    
    func resetProcess() {
        selectedFile = nil
        isImporting = false
        lastError = nil
        summary = nil
    }
}


struct FileUtil {
    func open(_ url: URL) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                throw DataTransferError.wrongFile("Could not get content from file \(url.absoluteString)")
            }
            return content
        } catch {
            
            throw DataTransferError.wrongFile("Could not open file \(url.absoluteString)")
        }
    }
}
