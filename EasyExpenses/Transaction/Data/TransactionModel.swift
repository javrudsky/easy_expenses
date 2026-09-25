import Foundation
import SwiftData

@Model
final class TransactionModel {
    var id: String
    var date: TimeInterval
    var category: String
    var detail: String?
    var transactionType: String
    var account: String
    var amount: Decimal

    init(id: String = UUID().uuidString,
         date: TimeInterval,
         category: String,
         detail: String?,
         transactionType: String,
         account: String,
         amount: Decimal) {
        self.id = id
        self.date = date
        self.category = category
        self.detail = detail
        self.transactionType = transactionType
        self.account = account
        self.amount = amount
    }
}
