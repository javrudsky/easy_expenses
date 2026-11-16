import Foundation

enum ImportLogLineType: String {
    case error = "ERROR"
    case warning = "WARN"
}

struct ImportLogLine: Sendable {
    let type: ImportLogLineType
    let line: String
}

struct ImportLogSummary: Sendable {
    let lines: [ImportLogLine]
    var warningCount: Int { return lines.filter { $0.type == .warning }.count }
    var errorCount: Int { return lines.filter { $0.type == .error }.count }

    var log: String {
        return String(lines.map { log in  "[\(log.type.rawValue.uppercased())] - \(log.line)" }.joined(separator: "\n"))
    }
}

struct ImportSummary: Sendable {
    let logSummary: ImportLogSummary
    let categories: [Category]
    let duplicatedTransactions: [Transaction]
    let accounts: [Account]
    let transactions: [Transaction]
}

protocol ImportLogBuilder {
    mutating func add(_ line: ImportLogLine)
    mutating func add(contentsOf lineList: [ImportLogLine])
    func summary() -> ImportLogSummary
}

struct DefaultImportLogBuilder: ImportLogBuilder {
    private var lines: [ImportLogLine] = []

    mutating func add(_ line: ImportLogLine) {
        lines.append(line)
    }
    
    mutating func add(contentsOf lineList: [ImportLogLine]) {
        lines.append(contentsOf: lineList)
    }
    
    func summary() -> ImportLogSummary {
        return ImportLogSummary(lines: lines)
    }
}

/// Describes an import/export data migrator for the app database.
///
/// Responsibilities:
/// - Export: Perform a SELECT * FROM transactions joined with categories and accounts (IDs and names) and return a plain CSV string.
/// - Import: Parse a CSV string, split rows into categories, accounts, and transactions, insert/update in the correct order (categories, accounts, then transactions), and log conflicts to an importation log.
protocol DataTransferService {
    /// Exports all transactions joined with categories and accounts into a plain CSV string.
    /// Base columns (in order):
    /// transaction_id, date, transaction_type, amount, detail, category_id, category_name, account_id, account_name
    ///
    /// Premium builds also export category/account visuals:
    /// category_image_name, category_rgb_color, account_image_name, account_rgb_color
    func exportToCsv() async throws -> String

    /// Imports data from a CSV string.
    /// - Parameter csv: The full CSV content.
    /// Behavior:
    /// 1) Split data to categories, accounts, transactions by scanning columns.
    /// 2) Insert categories and accounts first, then transactions.
    /// 3) If an ID already exists:
    ///    - Transaction: compare transactionType, amount, category. If equal, skip; otherwise, log difference.
    ///    - Category/Account: compare name. If equal, skip; otherwise, log difference.
    ///    - Category/Account visuals: log differences but keep the stored value.
    /// 4) Records with a zero amount are skipped and logged.
    /// 5) All conflicts must be stored in an importation log.
    ///
    /// Premium builds accept optional visual columns:
    /// category_image_name, category_rgb_color, account_image_name, account_rgb_color
    func importFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary

    /// Imports a generic CSV that has no IDs.
    /// Expected columns (in any order):
    /// date, category, account, detail, amount
    ///
    /// Records with a zero amount are skipped and logged. Premium builds also
    /// accept the optional visual columns listed on `importFrom`.
    func importGenericFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary

    /// Persists a previously parsed import summary.
    ///
    /// Categories and accounts are saved before transactions so each transaction's
    /// relationships are present when it is inserted or updated.
    func executeImport(summary: ImportSummary) async throws
}

/// A simple default migrator scaffold. Replace persistence calls with your app's database layer.
struct DefaultDataTransferService: DataTransferService {

    private let categoryRepo: CategoryRepository
    private let accountRepo: AccountRepository
    private let transactionRepo: TransactionRepository
    private let genericImportService: DefaultAdvancedTransactionImportService
    private let hasPremium: Bool
    private static let requiredColumns = [
        "transaction_id",
        "date",
        "transaction_type",
        "amount",
        "detail",
        "category_id",
        "category_name",
        "account_id",
        "account_name"
    ]
    private static let visualColumns = [
        "category_image_name",
        "category_rgb_color",
        "account_image_name",
        "account_rgb_color"
    ]

    private var fileColumns: [String] {
        hasPremium ? Self.requiredColumns + Self.visualColumns : Self.requiredColumns
    }

    private var fileHeader: String {
        fileColumns.joined(separator: ",")
    }

    init(dataStore: DataStore, hasPremium: Bool = PremiumFeatures.isEnabled) {
        self.categoryRepo = dataStore.categoryRepo
        self.accountRepo = dataStore.accountRepo
        self.transactionRepo = dataStore.transactionRepo
        self.hasPremium = hasPremium
        self.genericImportService = DefaultAdvancedTransactionImportService(dataStore: dataStore,
                                                                           hasPremium: hasPremium)
    }

    // MARK: - Export
    func exportToCsv() async throws -> String {
        // Fetch transactions and join with categories and accounts using repository data
        // Assumptions about repository APIs:
        // - transactionRepo.getAll() -> [Transaction]
        // - categoryRepo.getById(_ id: String) -> Category?
        // - accountRepo.getById(_ id: String) -> Account?
        // Adjust names if your project differs.

        // Retrieve all transactions
        let transactions = try await transactionRepo.fetchAll()

        // Build CSV rows by joining to category and account names
        var rows: [[String]] = []
        rows.reserveCapacity(transactions.count)

        let iso8601 = ISO8601DateFormatter()
        for tx in transactions {
            let date = Date(timeIntervalSince1970: tx.date)
            let dateString = iso8601.string(from: date)
            var row: [String] = [
                tx.id.uuidString,
                dateString,
                tx.transactionType.rawValue,
                String(describing: tx.amount),
                tx.detail ?? "",
                tx.category.id.uuidString,
                tx.category.name,
                tx.account.id.uuidString,
                tx.account.name
            ]
            if hasPremium {
                row.append(contentsOf: [
                    tx.category.imageName,
                    tx.category.rgbColor,
                    tx.account.imageName,
                    tx.account.rgbColor
                ])
            }
            rows.append(row)
        }

        let csvRows = rows.map { $0.map(Self.csvEscape).joined(separator: ",") }
        let csv = ([fileHeader] + csvRows).joined(separator: "\n")
        return csv
    }

    // MARK: - Import
    func importFrom(csv: String, logBuilder: ImportLogBuilder = DefaultImportLogBuilder()) async throws -> ImportSummary {
        if csv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DataTransferError.invalidData("Invalid file header")
        }
        
        var log = logBuilder
        
        // Parse the entire document so newlines inside quoted fields remain part
        // of the field rather than becoming separate, invalid records.
        let rows = try Self.parseCsvRecords(csv)

        guard let headerRow = rows.first else { throw DataTransferError.invalidData("Invalid file header")}
        // Check if header is effectively empty
        let headerTrimmed = headerRow.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if headerTrimmed.isEmpty || (headerTrimmed.count == 1 && headerTrimmed[0].isEmpty) {
            throw DataTransferError.invalidData("Invalid file header")
        }
        var headers = headerRow
        if let firstHeader = headers.first {
            // Excel commonly writes a UTF-8 BOM before the first column name.
            headers[0] = firstHeader.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))
        }
        // Expected headers (order enforced here). If different order, map indices by name.

        // Build index map
        var idx: [String: Int] = [:]
        
        for (i, h) in headers.enumerated() { idx[h] = i }
        // Validate minimal required columns exist. Visual columns are optional.
        for key in Self.requiredColumns { if idx[key] == nil { throw DefaultDataTransferService.ImportError.missingColumn(key) } }

        // Temporary sets/dictionaries to aggregate unique categories and accounts prior to insertion
        var categoryIdx: [UUID: Category] = [:]
        var accountIdx: [UUID: Account] = [:]
        var categoryVisuals: [UUID: ImportedVisuals] = [:]
        var accountVisuals: [UUID: ImportedVisuals] = [:]
        var transactions: [Transaction] = []
        var transactionIDs = Set<UUID>()

        // Collect data
        // The first record is the header, which has already been validated above.
        for (lineIndex, cols) in rows.dropFirst().enumerated() {
            let lineNumber = lineIndex + 2
            
            if cols.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                log.add(emptyLineLog(number: lineNumber))
                continue
            }

            func val(_ key: String) -> String? {
                guard let i = idx[key] else {
                    return nil
                }
                guard cols.indices.contains(i) else { return nil }
                return cols[i]
            }

            func visualValue(_ aliases: [String]) -> String? {
                guard hasPremium else { return nil }
                return ImportVisualColumns.value(in: cols, headers: headers, aliases: aliases)
            }

            let categoryImageName = visualValue(ImportVisualColumns.categoryImageNameAliases)
            let categoryRGBColor = visualValue(ImportVisualColumns.categoryRGBColorAliases)
            let accountImageName = visualValue(ImportVisualColumns.accountImageNameAliases)
            let accountRGBColor = visualValue(ImportVisualColumns.accountRGBColorAliases)

            let tranIdStr = val("transaction_id") ?? ""
            guard let tranId = UUID(uuidString: tranIdStr) else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: "",
                                            message: "Invalid transaction ID", csvLine: lineNumber))
                continue
            }

            let tranTypeStr = val("transaction_type") ?? ""
            guard let tranType = TransactionType(rawValue: tranTypeStr) else {
                log.add(transactionErrorLog(transactionId: tranId.uuidString, transactionType: tranTypeStr.isEmpty ? "" : tranTypeStr,
                                            message: tranTypeStr.isEmpty ? "Missing transaction type" : "Missing transaction type", csvLine: lineNumber))
                continue
            }
            
            guard let category = buildCategory(id: val("category_id"), name: val("category_name"),
                                               transactionType: tranType,
                                               imageName: categoryImageName ?? AppDefaults.defaultCategoryImage,
                                               rgbColor: categoryRGBColor ?? AppDefaults.defaultCategoryColor) else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: "", categoryName: val("category_name") ?? "", accountName: "", detail: "",
                                            message: "Invalid category", csvLine: lineNumber))
                continue
            }
            guard let account = buildAccount(id: val("account_id"), name: val("account_name"),
                                             imageName: accountImageName ?? AppDefaults.defaultAccountImage,
                                             rgbColor: accountRGBColor ?? AppDefaults.defaultAccountColor) else  {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            categoryName: category.name, accountName: val("account_name") ?? "",
                                            message: "Invalid account", csvLine: lineNumber))
                continue
            }
            let dateStr = val("date") ?? ""
            guard let date = Self.parseISO8601Date(dateStr)?.timeIntervalSince1970 else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            categoryName: category.name, accountName: account.name, date: dateStr, 
                                            message: "Invalid date", csvLine: lineNumber))
                continue
            }
            
            let amountStr = val("amount") ?? ""
            guard let amount = Decimal(string: amountStr) else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: amountStr, categoryName: category.name, accountName: account.name, detail: "",
                                            message: "Invalid amount", csvLine: lineNumber))
                continue
            }

            guard amount != 0 else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: amountStr, categoryName: category.name, accountName: account.name,
                                            detail: val("detail") ?? "", message: "Amount cannot be zero",
                                            csvLine: lineNumber))
                continue
            }

            guard transactionIDs.insert(tranId).inserted else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                             amount: amountStr, categoryName: category.name, accountName: account.name,
                                             detail: val("detail") ?? "", message: "Duplicate transaction ID in CSV",
                                             csvLine: lineNumber))
                continue
            }

            let t = Transaction(
                id: tranId,
                date: date,
                category: category,
                detail: val("detail") ?? "",
                transactionType: tranType,
                account: account,
                amount: amount,
            )
            // Only entities belonging to a fully valid transaction may be
            // persisted by executeImport.
            categoryIdx[category.id] = category
            accountIdx[account.id] = account
            let importedCategoryVisuals = ImportedVisuals(imageName: categoryImageName,
                                                           rgbColor: categoryRGBColor)
            if importedCategoryVisuals.hasAny {
                var visuals = categoryVisuals[category.id] ?? ImportedVisuals()
                visuals.merge(importedCategoryVisuals)
                categoryVisuals[category.id] = visuals
            }

            let importedAccountVisuals = ImportedVisuals(imageName: accountImageName,
                                                          rgbColor: accountRGBColor)
            if importedAccountVisuals.hasAny {
                var visuals = accountVisuals[account.id] ?? ImportedVisuals()
                visuals.merge(importedAccountVisuals)
                accountVisuals[account.id] = visuals
            }
            transactions.append(t)
        }

        // Make sure the summary carries the visual values that were actually
        // present in the file. executeImport still preserves the stored values
        // for entities that already exist.
        for (id, visuals) in categoryVisuals {
            guard var category = categoryIdx[id] else { continue }
            if let imageName = visuals.imageName { category.imageName = imageName }
            if let rgbColor = visuals.rgbColor { category.rgbColor = rgbColor }
            categoryIdx[id] = category
        }
        for (id, visuals) in accountVisuals {
            guard var account = accountIdx[id] else { continue }
            if let imageName = visuals.imageName { account.imageName = imageName }
            if let rgbColor = visuals.rgbColor { account.rgbColor = rgbColor }
            accountIdx[id] = account
        }

        let categories = Array(categoryIdx.values)
        let accounts = Array(accountIdx.values)
        log.add(contentsOf: await ImportLogFactory.duplicateLogs(categories: categories,
                                                                 visuals: categoryVisuals,
                                                                 repository: categoryRepo))
        log.add(contentsOf: await ImportLogFactory.duplicateLogs(accounts: accounts,
                                                                 visuals: accountVisuals,
                                                                 repository: accountRepo))
        let transactionDuplicates = await ImportLogFactory.duplicateLogs(transactions: transactions,
                                                                          repository: transactionRepo)
        log.add(contentsOf: transactionDuplicates.lines)
        let dup = transactionDuplicates.duplicates
        return ImportSummary(logSummary: log.summary(),
                             categories: categories,
                             duplicatedTransactions: dup,
                             accounts: accounts,
                             transactions: transactions
        )
    }

    func importGenericFrom(csv: String, logBuilder: ImportLogBuilder = DefaultImportLogBuilder()) async throws -> ImportSummary {
        try await genericImportService.importFrom(csv: csv, logBuilder: logBuilder)
    }

    func executeImport(summary: ImportSummary) async throws {
        for category in summary.categories {
            // Colors and symbols are premium data. When the entity already
            // exists, keep the value stored in the database and only apply the
            // non-visual fields from the file.
            let categoryToSave: Category
            if let existing = try await categoryRepo.fetchBy(id: category.id) {
                categoryToSave = Category(id: category.id,
                                          name: category.name,
                                          transactionType: category.transactionType,
                                          imageName: existing.imageName,
                                          rgbColor: existing.rgbColor)
            } else {
                categoryToSave = category
            }
            try await categoryRepo.insertOrUpdate(categoryToSave)
        }

        for account in summary.accounts {
            let accountToSave: Account
            if let existing = try await accountRepo.fetchBy(id: account.id) {
                accountToSave = Account(id: account.id,
                                        name: account.name,
                                        imageName: existing.imageName,
                                        rgbColor: existing.rgbColor)
            } else {
                accountToSave = account
            }
            try await accountRepo.insertOrUpdate(accountToSave)
        }

        let duplicateTransactionIDs = Set(summary.duplicatedTransactions.map(\.id))
        for transaction in summary.transactions where !duplicateTransactionIDs.contains(transaction.id) {
            try await transactionRepo.insertOrUpdate(transaction)
        }
    }

    // MARK: - Persistence hooks (replace with real DB layer)
    private func buildAccount(id: String?, name: String?,
                              imageName: String?, rgbColor: String?) -> Account? {
        if let id, let id = UUID(uuidString: id),
           let name, !name.isEmpty,
           let imageName, !imageName.isEmpty,
           let rgbColor, !rgbColor.isEmpty {
            return Account(id: id, name: name, imageName: imageName, rgbColor: rgbColor)
        }
        return nil
    }
   
    private func buildCategory(id: String?, name: String?,
                               transactionType: TransactionType,
                               imageName: String?, rgbColor: String?) -> Category? {
        if let id, let id = UUID(uuidString: id),
            let name, !name.isEmpty,
            let imageName, !imageName.isEmpty,
           let rgbColor, !rgbColor.isEmpty {
            return Category(id: id, name: name, transactionType: transactionType,
                            imageName: imageName, rgbColor: rgbColor)
        }
        return nil
    }
    
    func emptyLineLog(number: Int) -> ImportLogLine {
        ImportLogFactory.emptyLineLog(number: number)
    }


    private static let naVal = ImportLogFactory.naVal
    // MARK: - Import log
    private func transactionErrorLog(transactionId: String, transactionType: String, amount: String = naVal,
                                     categoryName: String = naVal, accountName: String = naVal, detail: String = naVal, date: String = naVal,
                                     message: String, csvLine: Int) -> ImportLogLine {
        ImportLogFactory.transactionErrorLog(transactionId: transactionId, transactionType: transactionType,
                                             amount: amount, categoryName: categoryName, accountName: accountName,
                                             detail: detail, date: date, message: message, csvLine: csvLine)
    }

    // MARK: - CSV helpers

    private static func csvEscape(_ value: String) -> String {
       var needsQuotes = false
        var v = value
        if v.contains("\"") { v = v.replacingOccurrences(of: "\"", with: "\"\""); needsQuotes = true }
        if v.contains(",") || v.contains("\n") || v.contains("\r") { needsQuotes = true }
        return needsQuotes ? "\"\(v)\"" : v
    }

    private static func parseCsvRecords(_ csv: String) throws -> [[String]] {
        try CsvParser.parseRecords(csv)
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        CsvParser.parseDate(value)
    }

    // MARK: - Errors
    enum ImportError: Error, LocalizedError {
        case missingColumn(String)

        var errorDescription: String? {
            switch self {
            case .missingColumn(let name):
                return "CSV is missing required column: \(name)"
            }
        }
    }
}
