//
//  StubTransactionService.swift
//  ArgiMoneyTests
//
//  Created by Javier Avrudsky on 29/10/2026.
//

import Foundation
@testable import ArgiMoneyPremium

actor StubDataTransferService: DataTransferService {
    let exportedCSV: String
    let importSummary: ImportSummary
    private(set) var executionCount = 0
    private(set) var standardImportCount = 0
    private(set) var genericImportCount = 0

    init(exportedCSV: String, importSummary: ImportSummary) {
        self.exportedCSV = exportedCSV
        self.importSummary = importSummary
    }

    func exportToCsv() async throws -> String {
        exportedCSV
    }

    func importFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary {
        standardImportCount += 1
        return importSummary
    }

    func importGenericFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary {
        genericImportCount += 1
        return importSummary
    }

    func executeImport(summary: ImportSummary) async throws {
        executionCount += 1
    }
}
