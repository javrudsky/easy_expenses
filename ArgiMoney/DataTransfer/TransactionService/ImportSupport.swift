import Foundation

// MARK: - CSV parsing

/// Shared CSV parsing helpers used by both the standard and the generic import flows.
enum CsvParser {

    /// Parses a CSV document into records. Quoted fields may contain commas,
    /// escaped quotes and newlines.
    static func parseRecords(_ csv: String) throws -> [[String]] {
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
                    i += 1
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
                } else {
                    field.append(c)
                    i += 1
                    continue
                }
            }
        }

        guard !inQuotes else {
            throw DataTransferError.invalidData(String(localized: "Unterminated quoted CSV field"))
        }

        // A trailing newline is common in spreadsheet exports. It should not
        // produce an extra empty record (which would be reported as an error),
        // but intentional blank lines inside the document are still kept.
        if !record.isEmpty || !field.isEmpty {
            record.append(field)
            records.append(record)
        }
        return records
    }

    /// Parses ISO-8601 timestamps and the common date-only form `yyyy-MM-dd`.
    static func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: trimmed) {
            return date
        }
        if let date = ISO8601DateFormatter().date(from: trimmed) {
            return date
        }

        // Date-only values are interpreted as UTC midnight so imports are deterministic.
        return parseDateOnly(trimmed)
    }

    private static func parseDateOnly(_ value: String) -> Date? {
        let normalized = value.replacingOccurrences(of: "/", with: "-")
        let parts = normalized.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date
    }
}

// MARK: - Optional visual columns

/// Visual values that were actually present in an imported CSV row.
///
/// Keeping the two fields independent is important: a file may provide a
/// symbol but no color (or the other way around), and missing values must not
/// be reported as conflicts with the stored entity.
struct ImportedVisuals: Equatable {
    var imageName: String? = nil
    var rgbColor: String? = nil

    var hasAny: Bool {
        imageName != nil || rgbColor != nil
    }

    mutating func merge(_ other: ImportedVisuals) {
        if let imageName = other.imageName {
            self.imageName = imageName
        }
        if let rgbColor = other.rgbColor {
            self.rgbColor = rgbColor
        }
    }
}

/// Column names used to import category/account colors and symbols.
///
/// Visual columns are optional and only honored for premium builds. Several
/// aliases are accepted so files produced by older/newer versions or by hand
/// keep working.
enum ImportVisualColumns {
    static let categoryImageNameAliases = [
        "category_image_name", "category_imagename", "category_image", "category_symbol"
    ]
    static let categoryRGBColorAliases = [
        "category_rgb_color", "category_rgbcolor", "category_color", "category_rgb"
    ]
    static let accountImageNameAliases = [
        "account_image_name", "account_imagename", "account_image", "account_symbol"
    ]
    static let accountRGBColorAliases = [
        "account_rgb_color", "account_rgbcolor", "account_color", "account_rgb"
    ]

    /// Returns the first non-empty value matching one of the aliases.
    static func value(in columns: [String], headers: [String], aliases: [String]) -> String? {
        for alias in aliases {
            guard let index = headers.firstIndex(where: {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == alias
            }), columns.indices.contains(index) else {
                continue
            }

            let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                return value
            }
        }
        return nil
    }
}

// MARK: - Import log formatting

/// Builds the log lines shared by the standard and generic import flows.
enum ImportLogFactory {

    static let naVal = "NA"

    static func emptyLineLog(number: Int) -> ImportLogLine {
        return ImportLogLine(type: .error, line: "\(logDate()) - [ERROR] Line \(number)")
    }

    static func transactionErrorLog(transactionId: String, transactionType: String, amount: String = naVal,
                                    categoryName: String = naVal, accountName: String = naVal, detail: String = naVal,
                                    date: String = naVal, message: String, csvLine: Int) -> ImportLogLine {
        var lineMsg: String = "CSV line: \(csvLine) "
        if csvLine == 0 {
            lineMsg = ""
        }

        let line = "\(logDate()) (\(lineMsg))-> TranId: '\(transactionId)', type: '\(transactionType)', date: '\(date)', amount: '\(amount)', category: '\(categoryName)', account: '\(accountName)', detail: '\(detail)': message='\(message)'"
        return ImportLogLine(type: .error, line: line)
    }

    static func entityErrorLog(transactionId: String, transactionType: String, id: String, name: String, isCat: Bool,
                               message: String, csvLine: Int) -> ImportLogLine {
        var lineMsg: String = "CSV line: \(csvLine) "
        if csvLine == 0 {
            lineMsg = ""
        }
        let entity = isCat ? "Category" : "Account"
        let line = "\(logDate()) \(lineMsg)-> TranId: \(transactionId): \(message) - Item type: '\(entity)' (id: '\(id)', name: '\(name)')"
        return ImportLogLine(type: .error, line: line)
    }

    static func importConflictLog(transactionId: String, transactionType: String, entity: String, id: String,
                                  field: String, existing: String, incoming: String, csvLine: Int) -> ImportLogLine {
        var lineMsg: String = "CSV line: \(csvLine) - "
        if csvLine == 0 {
            lineMsg = ""
        }
        let line = "\(logDate()) \(lineMsg)CONFLICT -> TranId: \(transactionId) -> Item type: '\(entity)', Value='\(field)' existing=\(existing) incoming=\(incoming)"
        return ImportLogLine(type: .error, line: line)
    }

    static func transactionDuplicatedLog(transactionId: String, transactionType: String, amount: String = naVal,
                                         categoryName: String = naVal, accountName: String = naVal, detail: String = naVal,
                                         date: String = naVal, csvLine: Int) -> ImportLogLine {
        var lineMsg: String = "CSV line: \(csvLine) - "
        if csvLine == 0 {
            lineMsg = ""
        }

        let line = "\(logDate()) \(lineMsg)DUPLICATED -> TranId: '\(transactionId)', type: '\(transactionType)', date: '\(date)', amount: '\(amount)', category: '\(categoryName)', account: '\(accountName)', detail: '\(detail)'"
        return ImportLogLine(type: .warning, line: line)
    }

    static func transactionConflictLog(transactionId: String, transactionType: String, field: String, existing: String,
                                       incoming: String, csvLine: Int) -> ImportLogLine {
        var lineMsg: String = "CSV line: \(csvLine) - "
        if csvLine == 0 {
            lineMsg = ""
        }
        let line = "\(logDate()) \(lineMsg) CONFLICT TranId: \(transactionId) -> value='\(field)' existing=\(existing) incoming=\(incoming)"
        return ImportLogLine(type: .error, line: line)
    }

    static func logDate() -> String {
        return Date().ISO8601Format()
    }

    // MARK: - Duplicate detection

    /// Compares incoming accounts with the ones already stored and returns the
    /// conflict/error lines so the caller can add them to its log.
    ///
    /// - Parameter visuals: Visual values that came from the CSV, keyed by
    ///   entity ID. Only those fields are compared so files without visual
    ///   columns do not produce false conflicts against stored values.
    static func duplicateLogs(accounts: [Account],
                              visuals: [UUID: ImportedVisuals] = [:],
                              repository: AccountRepository) async -> [ImportLogLine] {
        var lines: [ImportLogLine] = []
        for item in accounts {
            do {
                if let existing = try await repository.fetchBy(id: item.id) {
                    if existing.name != item.name {
                        lines.append(importConflictLog(transactionId: "", transactionType: "",
                                                       entity: "account", id: item.id.uuidString,
                                                       field: "name", existing: existing.name,
                                                       incoming: item.name, csvLine: 0))
                    }
                    if let imported = visuals[item.id] {
                        lines.append(contentsOf: visualConflictLogs(existingImageName: existing.imageName,
                                                                    existingRGBColor: existing.rgbColor,
                                                                    imported: imported,
                                                                    entity: "account", id: item.id))
                    }
                }
            } catch {
                lines.append(entityErrorLog(transactionId: "", transactionType: "", id: item.id.uuidString,
                                            name: item.name, isCat: false,
                                             message: String(localized: "Error retrieving from DB"), csvLine: 0))
            }
        }
        return lines
    }

    /// Compares incoming categories with the ones already stored and returns the
    /// conflict/error lines so the caller can add them to its log.
    static func duplicateLogs(categories: [Category],
                              visuals: [UUID: ImportedVisuals] = [:],
                              repository: CategoryRepository) async -> [ImportLogLine] {
        var lines: [ImportLogLine] = []
        for item in categories {
            do {
                if let existing = try await repository.fetchBy(id: item.id) {
                    if existing.name != item.name {
                        lines.append(importConflictLog(transactionId: "", transactionType: "",
                                                       entity: "category", id: item.id.uuidString,
                                                       field: "name", existing: existing.name,
                                                       incoming: item.name, csvLine: 0))
                    }
                    if existing.transactionType != item.transactionType {
                        lines.append(importConflictLog(transactionId: "", transactionType: "",
                                                       entity: "category", id: item.id.uuidString,
                                                       field: "type",
                                                       existing: existing.transactionType.rawValue,
                                                       incoming: item.transactionType.rawValue, csvLine: 0))
                    }
                    if let imported = visuals[item.id] {
                        lines.append(contentsOf: visualConflictLogs(existingImageName: existing.imageName,
                                                                    existingRGBColor: existing.rgbColor,
                                                                    imported: imported,
                                                                    entity: "category", id: item.id))
                    }
                }
            } catch {
                lines.append(entityErrorLog(transactionId: "", transactionType: "", id: item.id.uuidString,
                                            name: item.name, isCat: true,
                                             message: String(localized: "Error retrieving from DB"), csvLine: 0))
            }
        }
        return lines
    }

    private static func visualConflictLogs(existingImageName: String,
                                           existingRGBColor: String,
                                           imported: ImportedVisuals,
                                           entity: String, id: UUID) -> [ImportLogLine] {
        var lines: [ImportLogLine] = []
        if let imageName = imported.imageName, existingImageName != imageName {
            lines.append(importConflictLog(transactionId: "", transactionType: "",
                                           entity: entity, id: id.uuidString,
                                           field: "imageName", existing: existingImageName,
                                           incoming: imageName, csvLine: 0))
        }
        if let rgbColor = imported.rgbColor, existingRGBColor != rgbColor {
            lines.append(importConflictLog(transactionId: "", transactionType: "",
                                           entity: entity, id: id.uuidString,
                                           field: "rgbColor", existing: existingRGBColor,
                                           incoming: rgbColor, csvLine: 0))
        }
        return lines
    }

    /// Compares incoming transactions with the stored ones and returns the
    /// conflict/error lines plus the transactions that are exact duplicates.
    static func duplicateLogs(transactions: [Transaction],
                              repository: TransactionRepository) async -> (lines: [ImportLogLine], duplicates: [Transaction]) {
        var lines: [ImportLogLine] = []
        var duplicates: [Transaction] = []

        for tran in transactions {
            do {
                if let existing = try await repository.fetchBy(id: tran.id) {
                    var isDup = true
                    if existing.transactionType != tran.transactionType {
                        lines.append(transactionConflictLog(transactionId: tran.id.uuidString,
                                                            transactionType: tran.transactionType.rawValue,
                                                            field: "transaction_type",
                                                            existing: existing.transactionType.rawValue,
                                                            incoming: tran.transactionType.rawValue,
                                                            csvLine: 0))
                        isDup = false
                    }

                    if existing.amount != tran.amount {
                        lines.append(transactionConflictLog(transactionId: tran.id.uuidString,
                                                            transactionType: tran.transactionType.rawValue,
                                                            field: "amount",
                                                            existing: String(describing: existing.amount),
                                                            incoming: String(describing: tran.amount),
                                                            csvLine: 0))
                        isDup = false
                    }

                    if existing.category.id != tran.category.id {
                        lines.append(transactionConflictLog(transactionId: tran.id.uuidString,
                                                            transactionType: tran.transactionType.rawValue,
                                                            field: "category",
                                                            existing: existing.category.id.uuidString,
                                                            incoming: tran.category.id.uuidString,
                                                            csvLine: 0))
                        isDup = false
                    }

                    if existing.account.id != tran.account.id {
                        lines.append(transactionConflictLog(transactionId: tran.id.uuidString,
                                                            transactionType: tran.transactionType.rawValue,
                                                            field: "account",
                                                            existing: existing.account.id.uuidString,
                                                            incoming: tran.account.id.uuidString,
                                                            csvLine: 0))
                        isDup = false
                    }

                    if isDup {
                        lines.append(transactionDuplicatedLog(transactionId: tran.id.uuidString,
                                                              transactionType: tran.transactionType.rawValue,
                                                              amount: "\(tran.amount)",
                                                              categoryName: tran.category.name,
                                                              accountName: tran.account.name,
                                                              detail: tran.detail ?? "", csvLine: 0))
                        duplicates.append(tran)
                    }
                }
            } catch {
                let errMessage = "Error validation duplicate for transaction id: \(tran.id.uuidString)"
                lines.append(transactionErrorLog(transactionId: tran.id.uuidString,
                                                 transactionType: tran.transactionType.rawValue,
                                                 amount: String(describing: tran.amount),
                                                 categoryName: tran.category.name,
                                                 accountName: tran.account.name,
                                                 detail: tran.detail ?? "",
                                                 message: errMessage, csvLine: 0))
            }
        }
        return (lines, duplicates)
    }
}
