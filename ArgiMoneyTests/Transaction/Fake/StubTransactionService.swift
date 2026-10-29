//
//  StubTransactionService.swift
//  ArgiMoneyTests
//
//  Created by Javier Avrudsky on 29/10/2026.
//

import Foundation
@testable import ArgiMoney

actor StubDataTransferService: DataTransferService {
    let exportedCSV: String
    let importSummary: ImportSummary
    private(set) var executionCount = 0

    init(exportedCSV: String, importSummary: ImportSummary) {
        self.exportedCSV = exportedCSV
        self.importSummary = importSummary
    }

    func exportToCsv() async throws -> String {
        exportedCSV
    }

    func importFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary {
        importSummary
    }

    func executeImport(summary: ImportSummary) async throws {
        executionCount += 1
    }
}
