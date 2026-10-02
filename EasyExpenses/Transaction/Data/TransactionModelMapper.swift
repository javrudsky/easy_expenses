import Foundation

protocol TransactionMapper: Sendable {
    func toModel(_ domain: Transaction, categoryModel: CategoryModel, accountModel: AccountModel) -> TransactionModel
    func toDomain(_ model: TransactionModel) -> Transaction
}

struct DefaultTransactionMapper: TransactionMapper {
    func toModel(_ domain: Transaction, categoryModel: CategoryModel, accountModel: AccountModel) -> TransactionModel {
        return TransactionModel(
            id: domain.id,
            date: domain.date,
            detail: domain.detail,
            transactionType: domain.transactionType.rawValue,
            amount: domain.amount,
            category: categoryModel,
            account: accountModel
        )
    }

    func toDomain(_ model: TransactionModel) -> Transaction {
        let type = TransactionType(rawValue: model.transactionType) ?? .expense
        let category = Category(id: model.category.id, name: model.category.name, transactionType: type)
                                    let account = Account(id: model.account.id, name: model.account.name)
        return Transaction(
            id: model.id,
            date: model.date,
            category: category,
            detail: model.detail,
            transactionType: type,
            account: account,
            amount: model.amount
        )
    }
}
