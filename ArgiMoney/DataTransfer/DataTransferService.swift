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
    /// Expected Columns (in order):
    /// transaction_id, date, transaction_type, amount, note, category_id, category_name, account_id, account_name
    func exportToCsv() async throws -> String

    /// Imports data from a CSV string.
    /// - Parameter csv: The full CSV content.
    /// Behavior:
    /// 1) Split data to categories, accounts, transactions by scanning columns.
    /// 2) Insert categories and accounts first, then transactions.
    /// 3) If an ID already exists:
    ///    - Transaction: compare transactionType, amount, category. If equal, skip; otherwise, log difference.
    ///    - Category/Account: compare name. If equal, skip; otherwise, log difference.
    /// 4) All conflicts must be stored in an importation log.
    func importFrom(csv: String, logBuilder: ImportLogBuilder) async throws -> ImportSummary

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
    private static let fileColumns = [
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
    
    private static let fileHeader = fileColumns.joined(separator: ",")


    init(dataStore: DataStore) {
        self.categoryRepo = dataStore.categoryRepo
        self.accountRepo = dataStore.accountRepo
        self.transactionRepo = dataStore.transactionRepo
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
            let row: [String] = [
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
            rows.append(row)
        }

        let csvRows = rows.map { $0.map(Self.csvEscape).joined(separator: ",") }
        let csv = ([Self.fileHeader] + csvRows).joined(separator: "\n")
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
        // Validate minimal required columns exist
        for key in Self.fileColumns { if idx[key] == nil { throw DefaultDataTransferService.ImportError.missingColumn(key) } }

        // Temporary sets/dictionaries to aggregate unique categories and accounts prior to insertion
        var categoryIdx: [UUID: Category] = [:]
        var accountIdx: [UUID: Account] = [:]
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
            
            guard let category = buildCategory(id: val("category_id"), name: val("category_name"), transactionType: tranType) else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: "", categoryName: val("category_name") ?? "", accountName: "", detail: "",
                                            message: "Invalid category", csvLine: lineNumber))
                continue
            }
            guard let account = buildAccount(id: val("account_id"), name: val("account_name")) else  {
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
            transactions.append(t)
        }

        let categories = Array(categoryIdx.values)
        let accounts = Array(accountIdx.values)
        log.add(contentsOf: await logDuplicates(categories: categories).lines)
        log.add(contentsOf: await logDuplicates(accounts: accounts).lines)
        let (tlog, dup) = await logDuplicates(transactions: transactions)
        log.add(contentsOf: tlog.lines)
        return ImportSummary(logSummary: log.summary(),
                             categories: categories,
                             duplicatedTransactions: dup,
                             accounts: accounts,
                             transactions: transactions
        )
    }

    func executeImport(summary: ImportSummary) async throws {
        for category in summary.categories {
            try await categoryRepo.insertOrUpdate(category)
        }

        for account in summary.accounts {
            try await accountRepo.insertOrUpdate(account)
        }

        let duplicateTransactionIDs = Set(summary.duplicatedTransactions.map(\.id))
        for transaction in summary.transactions where !duplicateTransactionIDs.contains(transaction.id) {
            try await transactionRepo.insertOrUpdate(transaction)
        }
    }

    // MARK: - Persistence hooks (replace with real DB layer)
    private func buildAccount(id: String?, name: String?) -> Account? {
        if let id, let id = UUID(uuidString: id), let name, !name.isEmpty {
            return Account(id: id, name: name)
        }
        return nil
    }
   
    private func buildCategory(id: String?, name: String?, transactionType: TransactionType) -> Category? {
        if let id, let id = UUID(uuidString: id), let name, !name.isEmpty {
            return Category(id: id, name: name, transactionType: transactionType)
        }
        return nil
    }
    
    private func logDuplicates(accounts: [Account]) async -> ImportLogSummary {
        var log = DefaultImportLogBuilder()
        for item in accounts {
            do {
                if let existing = try await accountRepo.fetchBy(id: item.id) {
                    if existing.name != item.name {
                        log.add(importConflictLog(transactionId: "", transactionType: "",
                                                  entity: "account", id: item.id.uuidString,
                                                  field: "name", existing: existing.name, incoming: item.name, csvLine: 0))
                    }
                }
            } catch {
                log.add(entityErrorLog(transactionId: "", transactionType: "", id: item.id.uuidString, name: item.name,
                                       isCat: true, message: "Error retrieving from DB", csvLine: 0))
            }
        }
        return log.summary()
    }
    
    private func logDuplicates(categories: [Category]) async -> ImportLogSummary {
        var log = DefaultImportLogBuilder()
        for item in categories {
            do {
                if let existing = try await categoryRepo.fetchBy(id: item.id) {
                    if existing.name != item.name {
                        log.add(importConflictLog(transactionId: "", transactionType: "",
                                                  entity: "category", id: item.id.uuidString,
                                                  field: "name", existing: existing.name, incoming: item.name, csvLine: 0))
                    }
                    if existing.transactionType != item.transactionType {
                        log.add(importConflictLog(transactionId: "", transactionType: "",
                                                  entity: "category", id: item.id.uuidString, field: "type",
                                                  existing: existing.transactionType.rawValue,
                                                  incoming: item.transactionType.rawValue, csvLine: 0))
                    }
                }
            } catch {
                log.add(entityErrorLog(transactionId: "", transactionType: "", id: item.id.uuidString, name: item.name,
                                       isCat: true, message: "Error retrieving from DB", csvLine: 0))
            }
        }
        return log.summary()
    }


    /// Upsert transaction comparing transactionType, amount, and category when ID exists; log differences when not equal.
    private func logDuplicates(transactions: [Transaction]) async -> (ImportLogSummary, [Transaction]) {

        var log = DefaultImportLogBuilder()
        var duplicates: [Transaction] = []
        
        for tran in transactions {
            do {
                if let existing = try await transactionRepo.fetchBy(id: tran.id) {
                    var isDup = true
                    if existing.transactionType != tran.transactionType {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "transaction_type",
                                                       existing: existing.transactionType.rawValue,
                                                       incoming: tran.transactionType.rawValue,
                                                       csvLine: 0))
                        isDup = false
                    }
                    
                    if existing.amount != tran.amount {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "amount",
                                                       existing: String(describing: existing.amount),
                                                       incoming: String(describing: tran.amount),
                                                       csvLine: 0))
                        isDup = false
                    }
                    
                    if existing.category.id != tran.category.id {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "category",
                                                       existing: existing.category.id.uuidString,
                                                       incoming: tran.category.id.uuidString,
                                                       csvLine: 0))
                        isDup = false
                    }
                    
                    if existing.account.id != tran.account.id {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "account",
                                                       existing: existing.account.id.uuidString,
                                                       incoming: tran.account.id.uuidString,
                                                       csvLine: 0))
                        isDup = false
                    }
                    
                    if isDup {
                        log.add(transactionDuplicatedLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                         amount: "\(tran.amount)", categoryName: tran.category.name, accountName: tran.account.name,
                                                         detail: tran.detail ?? "", csvLine: 0))
                        duplicates.append(tran)
                    }
                }
            } catch {
                let errMessage = "Error validation duplicate for transaction id: \(tran.id.uuidString)"
                log.add(transactionErrorLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                            amount: String(describing: tran.amount), categoryName: tran.category.name,
                                            accountName: tran.account.name, detail: tran.detail ?? "",
                                            message: errMessage, csvLine: 0))
            }
        }
        return (log.summary(), duplicates)
    }
    
    func emptyLineLog(number: Int) -> ImportLogLine {
        return ImportLogLine(type: .error, line: "\(logDate()) - [ERROR] Line \(number)")
    }


    private static let naVal = "NA"
    // MARK: - Import log
    private func transactionErrorLog(transactionId: String, transactionType: String, amount: String = naVal,
                                     categoryName: String = naVal, accountName: String = naVal, detail: String = naVal, date: String = naVal,
                                     message: String, csvLine: Int) -> ImportLogLine {
        
        var lineMsg: String = "CSV line: \(csvLine) "
        if csvLine == 0 {
           lineMsg = ""
        }
        
        let line = "\(logDate()) (\(lineMsg))-> TranId: '\(transactionId)', type: '\(transactionType)', date: '\(date)', amount: '\(amount)', category: '\(categoryName)', account: '\(accountName)', detail: '\(detail)': message='\(message)'"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func entityErrorLog(transactionId: String, transactionType: String, id: String, name: String, isCat: Bool,
                                message: String, csvLine: Int) -> ImportLogLine {
        
        var lineMsg: String = "CSV line: \(csvLine) "
        if csvLine == 0 {
           lineMsg = ""
        }
        let entity = isCat ? "Category" : "Account"
        let line = "\(logDate()) \(lineMsg)-> TranId: \(transactionId): \(message) - Item type: '\(entity)' (id: '\(id)', name: '\(name)')"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func importConflictLog(transactionId: String, transactionType: String, entity: String, id: String,
                                   field: String, existing: String, incoming: String, csvLine: Int) -> ImportLogLine {
        
        var lineMsg: String = "CSV line: \(csvLine) - "
        if csvLine == 0 {
           lineMsg = ""
        }
        let line = "\(logDate()) \(lineMsg)CONFLICT -> TranId: \(transactionId) -> Item type: '\(entity)', Value='\(field)' existing=\(existing) incoming=\(incoming)"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func transactionDuplicatedLog(transactionId: String, transactionType: String, amount: String = naVal,
                                          categoryName: String = naVal, accountName: String = naVal, detail: String = naVal,
                                          date: String = naVal, csvLine: Int) -> ImportLogLine {
       
        var lineMsg: String = "CSV line: \(csvLine) - "
        if csvLine == 0 {
           lineMsg = ""
        }
        
        let line = "\(logDate()) \(lineMsg)DUPLICATED -> TranId: '\(transactionId)', type: '\(transactionType)', date: '\(date)', amount: '\(amount)', category: '\(categoryName)', account: '\(accountName)', detail: '\(detail)'"
        return ImportLogLine(type: .warning, line: line)
    }

    private func transactionConflictLog(transactionId: String, transactionType: String, field: String, existing: String,
                                        incoming: String, csvLine: Int) -> ImportLogLine {
        
        var lineMsg: String = "CSV line: \(csvLine) - "
        if csvLine == 0 {
           lineMsg = ""
        }
        let line = "\(logDate()) \(lineMsg) CONFLICT TranId: \(transactionId) -> value='\(field)' existing=\(existing) incoming=\(incoming)"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func logDate() -> String {
        return Date().ISO8601Format()
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
        var records: [[String]] = []
        var field = ""
        var inQuotes = false
        let chars = Array(csv)
        var record: [String] = []
        var i = 0
        
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                        i += 1
                        continue
                    }
                } else if c == "\n" || c == "\r\n" {
                    // Swift takes a "\r\n" as a grapheme cluster
                    field.append(c)
//                    if c == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
//                        i += 2
//                    } else {
                        i += 1
//                    }
                    continue
                } else {
                    field.append(c)
                    i += 1
                    continue
                }
            } else {
                if c == "\"" && field.isEmpty {
                    inQuotes = true
                    i += 1
                    continue
                } else if c == "," {
                    record.append(field)
                    field = ""
                    i += 1
                    continue
                } else if c == "\n" || c == "\r\n" {
                    // Swift takes a "\r\n" as a grapheme cluster
                    record.append(field)
                    field = ""
                    records.append(record)
                    record = []
                    i += 1
                    continue
//                } else if c == "\r" {
//                    if i + 1 < chars.count && chars[i + 1] == "\n" {
//                        i += 2
//                    } else {
//                        i += 1
//                    }
//                    record.append(field)
//                    field = ""
//                    records.append(record)
//                    record = []
//                    continue
                } else {
                    if field == "account_name" {
                        print("pepe")
                    }
                    field.append(c)
                    i += 1
                    continue
                }
            }
        }
        
        guard !inQuotes else {
            throw DataTransferError.invalidData("Unterminated quoted CSV field")
        }
        
        record.append(field)
        records.append(record)
        return records
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }
        return ISO8601DateFormatter().date(from: value)
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
