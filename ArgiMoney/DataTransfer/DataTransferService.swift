import Foundation

enum ImportLogLineType: String {
    case error
    case warning
}

struct ImportLogLine: Sendable {
    let type: ImportLogLineType
    let line: String
}

struct ImportLogSummary: Sendable {
    let lines: [ImportLogLine]
    var warningCount: Int { return lines.filter { $0.type == .warning }.count }
    var errorCount: Int { return lines.filter { $0.type == .warning }.count }
    
    var log: String {
        return String(lines.map { log in  "[\(log.type.rawValue.uppercased())] - \(log.line)" }.joined(separator: "\n"))
    }
}

struct ImportSummary: Sendable {
    let logSummary: ImportLogSummary
    let categories: [Category]
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
        
        var log = logBuilder
        
        // Parse CSV into rows
        let lines = csv.split(whereSeparator: { $0.isNewline })
        
        
        guard let headerLine = lines.first else { throw MigrationError.invalidData("Invalid file header")}
        let headers = Self.parseCsvLine(String(headerLine))
        // Expected headers (order enforced here). If different order, map indices by name.

        // Build index map
        var idx: [String: Int] = [:]
        
        for (i, h) in headers.enumerated() { idx[h] = i }
        // Validate minimal required columns exist
        for key in Self.fileColumns { if idx[key] == nil { throw ImportError.missingColumn(key) } }

        // Temporary sets/dictionaries to aggregate unique categories and accounts prior to insertion
        var categoryIdx: [UUID: Category] = [:]
        var accountIdx: [UUID: Account] = [:]
        var transactions: [Transaction] = []

        // Collect data
        for (lineNumber, line) in lines.enumerated() {
            
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                log.add(emptyLineLog(number: lineNumber))
                continue
            }
            
            let cols = Self.parseCsvLine(String(line))
            func val(_ key: String) -> String? {
                guard let i = idx[key] else {
                    return nil
                }
                return cols[i]
            }
            
            let tranIdStr = val("transaction_id") ?? ""
            guard let tranId = UUID(uuidString: tranIdStr) else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: "",
                                            amount: "", categoryName: "", accountName: "", detail: "",
                                            message: "Invalid transaction ID", csvLine: lineNumber))
                continue
            }

            let tranTypeStr = val("transaction_type") ?? ""
            guard let tranType = TransactionType(rawValue: tranTypeStr) else {
                log.add(transactionErrorLog(transactionId: tranId.uuidString, transactionType: tranTypeStr,
                                            amount: "", categoryName: "", accountName: "", detail: "",
                                            message: "Missing transaction type", csvLine: lineNumber))
                continue
            }
            
            guard let category = buildCategory(id: val("category_id"), name: val("category_name"), transactionType: tranType) else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: "", categoryName: val("category_name") ?? "", accountName: "", detail: "",
                                            message: "Invalid category", csvLine: lineNumber))
                continue
            }
            categoryIdx[category.id] = category

            guard let account = buildAccount(id: val("account_id"), name: val("account_name")) else  {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: "", categoryName: category.name, accountName: val("account_name") ?? "", detail: "",
                                            message: "Invalid account", csvLine: lineNumber))
                continue
            }
            accountIdx[account.id] = account

            let iso8601 = ISO8601DateFormatter()
            let dateStr = val("date") ?? ""
            guard let date = iso8601.date(from: dateStr)?.timeIntervalSince1970 else {
                log.add(transactionErrorLog(transactionId: tranIdStr, transactionType: tranTypeStr,
                                            amount: "", categoryName: category.name, accountName: account.name, detail: "",
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

            let t = Transaction(
                id: tranId,
                date: date,
                category: category,
                detail: val("detail") ?? "",
                transactionType: tranType,
                account: account,
                amount: amount,
            )
            transactions.append(t)
        }

        let categories = Array(categoryIdx.values)
        let accounts = Array(accountIdx.values)
        log.add(contentsOf: await logDuplicates(categories: categories).lines)
        log.add(contentsOf: await logDuplicates(accounts: accounts).lines)
        log.add(contentsOf: await logDuplicates(transactions: transactions).lines)
        return ImportSummary(logSummary: log.summary(),
                             categories: categories,
                             accounts: accounts,
                             transactions: transactions)
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
    private func logDuplicates(transactions: [Transaction]) async -> ImportLogSummary {

        var log = DefaultImportLogBuilder()
        
        for tran in transactions {
            do {
                if let existing = try await transactionRepo.fetchBy(id: tran.id) {
                    if existing.transactionType != tran.transactionType {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "transaction_type",
                                                       existing: tran.transactionType.rawValue,
                                                       incoming: existing.transactionType.rawValue,
                                                       csvLine: 0))
                    }
                    if existing.amount != tran.amount {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "amount",
                                                       existing: String(describing: existing.amount),
                                                       incoming: String(describing: tran.amount),
                                                       csvLine: 0))
                    }
                    
                    if existing.category.id != tran.category.id {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "category",
                                                       existing: existing.category.id.uuidString,
                                                       incoming: tran.category.id.uuidString,
                                                       csvLine: 0))
                    }
                    
                    if existing.account.id != tran.account.id {
                        log.add(transactionConflictLog(transactionId: tran.id.uuidString, transactionType: tran.transactionType.rawValue,
                                                       field: "category",
                                                       existing: existing.category.id.uuidString,
                                                       incoming: tran.category.id.uuidString,
                                                       csvLine: 0))
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
        return log.summary()
    }
    
    func emptyLineLog(number: Int) -> ImportLogLine {
        return ImportLogLine(type: .error, line: "\(logDate()) - [ERROR] Line \(number)")
    }


    // MARK: - Import log
    private func transactionErrorLog(transactionId: String, transactionType: String, amount: String,
                                     categoryName: String, accountName: String, detail: String, message: String, csvLine: Int) -> ImportLogLine {
        let line = "\(logDate()) - (\(csvLine))[TRAN ERROR] T:\(transactionId)|\(transactionType)]  - amount: \(amount), category: \(categoryName), account: \(accountName), detail: \(detail): message=\(message)"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func entityErrorLog(transactionId: String, transactionType: String, id: String, name: String, isCat: Bool,
                                message: String, csvLine: Int) -> ImportLogLine {
        
        let entity = isCat ? "Category" : "Account"
        let line = "(\(logDate()) - (\(csvLine)[ENTITY] T:\(transactionId)|\(transactionType)] message=\(message) - \(entity)(id: \(id), name: \(name))"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func importConflictLog(transactionId: String, transactionType: String, entity: String, id: String,
                                   field: String, existing: String, incoming: String, csvLine: Int) -> ImportLogLine {
        let line = "\(logDate()) - (\(csvLine)[CONFLICT] T:[\(transactionId)|\(transactionType)] entity=\(entity) id=\(id) field=\(field) existing=\(existing) incoming=\(incoming)"
        return ImportLogLine(type: .error, line: line)
    }
    
    private func transactionConflictLog(transactionId: String, transactionType: String, field: String, existing: String,
                                        incoming: String, csvLine: Int) -> ImportLogLine {
        let line = "\(logDate()) - (\(csvLine)[CONFLICT] T:[\(transactionId)|\(transactionType)] entity=transaction field=\(field) existing=\(existing) incoming=\(incoming)"
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

    private static func parseCsvLine(_ line: String) -> [String] {
        // Minimal CSV parser for RFC 4180-like lines.
        var result: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(c)
                }
            } else {
                if c == "," {
                    result.append(current)
                    current = ""
                } else if c == "\"" {
                    inQuotes = true
                } else {
                    current.append(c)
                }
            }
            i += 1
        }
        result.append(current)
        return result
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
