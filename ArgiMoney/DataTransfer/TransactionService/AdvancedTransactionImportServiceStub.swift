import Foundation
import CryptoKit

/// Imports a "generic" CSV that has no IDs.
///
/// Accepted columns (in any order):
/// `date, category, account, detail, amount`
///
/// - `amount > 0` is imported as an income transaction, otherwise as an expense.
/// - Categories are identified by `name + transaction type`, so repeated names
///   with the same type share one generated ID.
/// - Accounts are identified by name. The `Account` model has no transaction
///   type, so the same account name always maps to the same generated ID.
/// - `detail` is optional and is stored as `nil` when empty or missing.
/// - Records with a zero amount are skipped and logged.
/// - Premium builds may also provide optional category/account visual columns.
protocol AdvancedTransactionImportService {
    func importFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary
}

struct DefaultAdvancedTransactionImportService: AdvancedTransactionImportService {

    init(dataStore: DataStore, hasPremium: Bool = PremiumFeatures.isEnabled) {
        // The community build does not include the advanced importer.
    }

    func importFrom(csv: String, logBuilder: ImportLogBuilder = DefaultImportLogBuilder()) async throws -> ImportSummary {
                
        return ImportSummary(logSummary: ImportLogSummary(lines: []),
                             categories: [],
                             duplicatedTransactions: [],
                             accounts: [],
                             transactions: [])
    }
    
}
