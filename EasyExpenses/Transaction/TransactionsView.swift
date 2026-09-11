//
//  TransactionsListView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import SwiftUI
import SwiftData
import Combine

struct TransactionsView<VM: TransactionsViewModelProtocol>: View {
    @StateObject private var viewModel: VM

    @State private var showDeleteConfirmation = false
    @State private var pendingDeleteOffsets: IndexSet = []

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
                                Text(tx.category).font(.headline)
                                Text(tx.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(tx.date, style: .date).font(.footnote).foregroundStyle(.secondary)
                                Text(amountString(for: tx)).font(.body).foregroundStyle(tx.isDebit ? .red : .green)
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
                Button("Delete", role: .destructive) { viewModel.delete(at: pendingDeleteOffsets) }
                Button("Cancel", role: .cancel) { pendingDeleteOffsets = [] }
            }
            .sheet(isPresented: $viewModel.showingForm) {
                TransactionFormView(transaction: viewModel.editingTransaction) { result in
                    switch result {
                    case .created(let date, let category, let detail, let type, let account, let amount):
                        let builder = TransactionBuilder()
                            .setting(date: date)
                            .setting(category: category)
                            .setting(account: account)
                            .setting(amount: amount)
                            .setting(detail: detail)
                        switch type {
                        case .debit:
                            viewModel.addDebit(using: builder)
                        case .credit:
                            viewModel.addCredit(using: builder)
                        }
                    case .updated(let tx):
                        viewModel.update(tx)
                    case .cancelled:
                        break
                    }
                }
            }
            .onAppear { viewModel.reload() }
        }
    }

    private func amountString(for tx: Transaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: tx.amount as NSDecimalNumber) ?? "\(tx.amount)"
    }
}

#Preview {
    let container = try! ModelContainer(for: Transaction.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let repo = SwiftDataTransactionRepository(context: context)
    let vm = TransactionsViewModel(repo: repo)
    return TransactionsView<TransactionsViewModel>(viewModel: vm)
}
