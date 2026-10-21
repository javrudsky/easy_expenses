import Foundation
import SwiftUI
import Combine


//enum ExportStatus {
//    case idle
//    case
//    case
//}

@MainActor
protocol ExportTransactionsViewModel: ObservableObject {
    
    var selectedRange: DateRange { get set }
    var fromDate: Date { get set }
    var toDate: Date { get set }
    var errorMessage: String? { get set }
    var isShareSheetVisible: Bool { get set }
    
    var exportURL: URL? { get }
    var isExporting: Bool { get }
    

    func exportToCsv() async
}

@MainActor
final class DefaultExportTransactionsViewModel: ExportTransactionsViewModel {
    // Input controls mirrored from the view
    @Published var selectedRange: DateRange = .currentMonth
    @Published var fromDate: Date = .now
    @Published var toDate: Date = .now
    @Published var errorMessage: String?
    @Published var isShareSheetVisible: Bool = false
    
    // Output
    @Published private(set) var exportURL: URL?
    @Published private(set) var isExporting: Bool = false

    private let dataTransferService: DataTransferService

    init(dataTransferService: DataTransferService) {
        self.dataTransferService = dataTransferService
    }

    /// Generates the CSV string using the underlying DataTransferService.
    /// Note: This method returns the CSV content and also stores a temporary file URL
    /// into `exportURL` for easy sharing from the UI.
    func exportToCsv() async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }

        do {
            // Delegate to the service to build the CSV content (currently exports all data).
            let csv = try await dataTransferService.exportToCsv()
            
            // Persist to a temporary file so ShareLink can use a URL.
            let fileName = suggestedFileName()
            let fileURL = try writeCSVToTemporaryFile(named: fileName, contents: csv)
            self.exportURL = fileURL
        } catch {
            errorMessage = "Error exporting transactions"
        }
    }

    // MARK: - Helpers

    private func suggestedFileName() -> String {
        switch selectedRange {
        case .currentMonth:
            let comps = Calendar.current.dateComponents([.year, .month], from: Date())
            let year = comps.year ?? 0
            let month = comps.month ?? 0
            return "argi-transactions-\(year)-\(String(format: "%02d", month)).csv"
        case .currentYear:
            let year = Calendar.current.component(.year, from: Date())
            return "argi-transactions-\(year).csv"
        case .custom:
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd"
            return "argi-transactions-\(df.string(from: fromDate))_to_\(df.string(from: toDate)).csv"
        case .all:
            return "argi-transactions.csv"
        }
    }

    private func writeCSVToTemporaryFile(named fileName: String, contents: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try contents.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}
