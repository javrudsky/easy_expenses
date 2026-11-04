//
//  CategoriesView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//
import SwiftUI

struct CategoriesView<VM: CategoriesViewModel>: View {
    @ObservedObject var viewModel: VM
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                NavigationLink {
                    CategoryEditView(category: category,
                                     transactionType: viewModel.transactionType,
                                     usedColors: viewModel.categories.map { $0.rgbColor }) { category in
                        save(category)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.imageName)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(rgbaCsv: category.rgbColor), in: Circle())
                        
                        Text(category.name)
                            .foregroundStyle(.primary)
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
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
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CategoryEditView(category: nil,
                                     transactionType: viewModel.transactionType,
                                     usedColors: viewModel.categories.map { $0.rgbColor }) { category in
                        save(category)
                    }
                } label: {
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
        Task {
            do {
                try await viewModel.save(category)
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

