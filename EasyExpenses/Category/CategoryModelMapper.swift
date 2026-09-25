//
//  CategoryModelMapper.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

protocol CategoryMapper: Sendable {
    func toDomain(_ model: CategoryModel) -> Category
    func toModel(_ domain: Category) -> CategoryModel
}

struct DefaultCategoryMapper: CategoryMapper {
    func toDomain(_ model: CategoryModel) -> Category {
        Category(id: model.id, name: model.name)
    }
    func toModel(_ domain: Category) -> CategoryModel {
        CategoryModel(id: domain.id, name: domain.name)
    }
}
