//
//  TransactionsListView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import SwiftUI
import SwiftData
import Combine

struct TransactionsView<VM: TransactionsViewModel>: View {
    @StateObject private var viewModel: VM

    @State private var showDeleteConfirmation = false
    @State private var pendingDeleteOffsets: IndexSet = []
    @State private var showingError = false
    @State private var errorMessage: String = ""

    init(viewModel: VM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.transactions) { tx in
                    Button {
                        viewModel.editingTransaction = tx
                        viewModel.showingForm = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tx.category.name).font(.headline)
                                Text(tx.detail ?? "").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(Date(timeIntervalSince1970: tx.date), style: .date).font(.footnote).foregroundStyle(.secondary)
                                Text(amountString(for: tx)).font(.body).foregroundStyle(tx.isExpense ? .red : .green)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    pendingDeleteOffsets = offsets
                    showDeleteConfirmation = true
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.editingTransaction = nil
                        viewModel.showingForm = true
                    } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add")
                }
            }
            .confirmationDialog("Delete selected transactions?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.delete(at: pendingDeleteOffsets)
                            pendingDeleteOffsets = []
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) { pendingDeleteOffsets = [] }
            }
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })
            .sheet(isPresented: $viewModel.showingForm) {
                let tran = viewModel.editingTransaction
                let config = TransactionFormConfig(transaction: tran,
                                                   crudOperation: (tran == nil ? .create : .update),
                                                   allCategories: viewModel.categories,
                                                   gridCategories: viewModel.gridCategories(categories: viewModel.categories,
                                                                                            selected: tran?.category),
                                                   accounts: viewModel.accounts)
                
                TransactionFormView(config: config) { handleResult(result: $0) }
            }
            .onAppear {
                reloadViewModel()
                reloadData()
            }
        }
        
    }
    
    // MARK: -- Private functions
    func reloadViewModel() {
        Task {
            do {
                try await viewModel.reload()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func amountString(for tx: Transaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: tx.amount as NSDecimalNumber) ?? "\(tx.amount)"
    }
    
    private func handleResult(result: TransactionFormResult) {
        switch result {
        case .created(let date, let category, let detail, let type, let account, let amount):
            let builder = TransactionBuilder()
                .setting(date: date.timeIntervalSince1970)
                .setting(category: category)
                .setting(account: account)
                .setting(amount: amount)
                .setting(detail: detail)
            Task {
                do {
                    switch type {
                    case .expense:
                        try await viewModel.addExpense(using: builder)
                    case .income:
                        try await viewModel.addIncome(using: builder)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        case .updated(let tx):
            Task {
                do {
                    try await viewModel.update(tx)
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        case .cancelled:
            break
        }
    }

    private func reloadData() {
        // TODO: Implement enable / disable logic after loading
        Task {
            await viewModel.reloadCategories()
            await viewModel.reloadAccounts()
        }
    }
}

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    let vm = cf.transactionsViewModel(dataStore: cf.dataStore()) as! DefaultTransactionsViewModel
    TransactionsView<DefaultTransactionsViewModel>(viewModel: vm)
}

