import Foundation


protocol TransactionMapper: Sendable {
    func toModel(_ domain: Transaction) -> TransactionModel
    func toDomain(_ model: TransactionModel) -> Transaction
}

struct DefaultTransactionMapper: TransactionMapper {

    func toModel(_ domain: Transaction) -> TransactionModel {
        return TransactionModel(
            id: domain.id,
            date: domain.date,
            category: domain.category,
            detail: domain.detail,
            transactionType: domain.transactionType.rawValue,
            account: domain.account,
            amount: domain.amount
        )
    }

    func toDomain(_ model: TransactionModel) -> Transaction {
        let type = TransactionType(rawValue: model.transactionType) ?? .debit
        return Transaction(
            id: model.id,
            date: model.date,
            category: model.category,
            detail: model.detail,
            transactionType: type,
            account: model.account,
            amount: model.amount
        )
    }
}
