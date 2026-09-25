//
//  AccountModelMapper.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation

protocol AccountMapper: Sendable {
    func toDomain(_ model: AccountModel) -> Account
    func toModel(_ domain: Account) -> AccountModel
}

struct DefaultAccountMapper: AccountMapper {
    func toDomain(_ model: AccountModel) -> Account { Account(id: model.id, name: model.name) }
    func toModel(_ domain: Account) -> AccountModel { AccountModel(id: domain.id, name: domain.name) }
}
