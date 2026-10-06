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
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

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
                        save(category)
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
            .onDelete { offsets in
                delete(offsets: offsets)
            }
            .alert("Unable to complete", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })

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
        
    private func delete(offsets: IndexSet) {
        Task {
            do {
                try await viewModel.delete(at: offsets)
            } catch {
                errorMessage = "You can’t delete this category while it has associated transactions. Remove or move those transactions first."
                showingError = true
            }
        }
    }
    
    private func save(_ category: Category) {
        let tType = viewModel.transactionType
        let updated = Category(id: category.id,
                               name: editingName[category.id] ?? category.name,
                               transactionType: tType)
        
        Task {
            do {
                try await viewModel.save(updated)
            } catch {
                errorMessage = "We couldn’t save your changes. Please try again."
                showingError = true
            }
        }
       
    }

}

#Preview {
    let repo = SwiftDataCategoryRepository(modelContainer: try! DefaultAppFactory.createModelContainer(inMemory: true))
    let vm = DefaultCategoriesViewModel(transactionType: .expense, repo: repo)
    CategoriesView(viewModel: vm)
}

