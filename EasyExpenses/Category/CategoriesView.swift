//
//  CategoriesView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//
import SwiftUI

struct CategoriesView<VM: CategoriesViewModel>: View {
    @ObservedObject var viewModel: VM
    @State private var editingName: [UUID: String] = [:]

    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                    TextField("Name", text: Binding(
                        get: { editingName[category.id] ?? category.name },
                        set: { editingName[category.id] = $0 }
                    ), onCommit: {
                        let updated = Category(id: category.id, name: editingName[category.id] ?? category.name)
                        Task { await viewModel.save(updated) }
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
            .onDelete { offsets in
                Task { await viewModel.delete(at: offsets) }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.add() }) {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Categories")
    }
}

#Preview {
    let repo = SwiftDataCategoryRepository(modelContainer: try! DefaultAppFactory.createModelContainer(inMemory: true))
    let vm = DefaultCategoriesViewModel(repo: repo)
    CategoriesView(viewModel: vm)
}

