import Foundation
import SwiftData

@Model
final class TransactionModel {
    @Attribute(.unique) var id: UUID
    var date: TimeInterval
    var detail: String?
    var transactionType: String
    var amount: Decimal

    @Relationship
    var category: CategoryModel
    
    @Relationship
    var account: AccountModel

    init(id: UUID = UUID(),
         date: TimeInterval,
         detail: String?,
         transactionType: String,
         amount: Decimal,
         category: CategoryModel,
         account: AccountModel) {
        self.id = id
        self.date = date
        self.detail = detail
        self.transactionType = transactionType
        self.amount = amount
        self.category = category
        self.account = account
    }
}
