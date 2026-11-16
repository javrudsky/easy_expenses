
import SwiftUI
import SwiftData
import Combine

struct TransactionsView<VM: TransactionsViewModel>: View {
    
    @StateObject private var viewModel: VM
    
    @AppStorage("transactionGrouping")
    private var grouping: TransactionGrouping = .day
    
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    
    @State private var showDeleteConfirmation = false
    @State private var pendingDeleteOffsets: IndexSet = []
    @State private var pendingDeleteTransaction: Transaction? = nil
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var showingMonthlySummary = true

    private let calendar = Calendar.current
    
    init(viewModel: VM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Data
    
    private var filteredTransactions: [Transaction] {
        viewModel.transactions
            .filter { tx in
                switch selectedFilter {
                case .all:
                    return true
                case .income:
                    return !tx.isExpense
                case .expenses:
                    return tx.isExpense
                }
            }
            .filter { tx in
                searchText.isEmpty ||
                tx.category.name.localizedCaseInsensitiveContains(searchText) ||
                (tx.detail ?? "")
                    .localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.date > $1.date }
    }
    
    private var groupedTransactions: [TransactionGroup] {
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            let date = Date(timeIntervalSince1970: tx.date)
            
            switch grouping {
            case .day:
                return calendar.startOfDay(for: date)
            case .month:
                return calendar.dateInterval(
                    of: .month,
                    for: date
                )!.start
            }
        }
        
        return grouped.map { date, transactions in
            TransactionGroup(
                date: date,
                transactions: transactions.sorted {
                    $0.date > $1.date
                }
            )
        }
        .sorted { $0.date > $1.date }
    }
    
    private var totalBalance: Decimal {
        viewModel.transactions.reduce(Decimal.zero) { result, tx in
            result + (tx.isExpense ? -tx.amount : tx.amount)
        }
    }
    
    private var currentMonthTransactions: [Transaction] {
        viewModel.transactions.filter { tx in
            calendar.isDate(
                Date(timeIntervalSince1970: tx.date),
                equalTo: Date(),
                toGranularity: .month
            )
        }
    }
    
    private var monthlyIncome: Decimal {
        currentMonthTransactions
            .filter { !$0.isExpense }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var monthlyExpenses: Decimal {
        currentMonthTransactions
            .filter(\.isExpense)
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var monthlyResult: Decimal {
        monthlyIncome - monthlyExpenses
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            totalBalanceCard
            MonthlyBalanceView(incomeAmount: monthlyIncome,
                              expensesAmount: monthlyExpenses,
                              resultAmount: monthlyResult,
                              showingDetail: true)
            searchAndFilter
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    // MARK: - Body
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                    .zIndex(1)
                
                ScrollView {
                    transactionsList
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        let config = TransactionFormConfig(
                            transaction: nil,
                            crudOperation: .create,
                            categories: viewModel.categories,
                            accounts: viewModel.accounts
                        )
                        TransactionFormView(config: config) {
                            handleResult(result: $0)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add")
                    .accessibilityIdentifier("add-transaction")
                }
            }
            .confirmationDialog(
                "Delete selected transactions?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deletePendingTransactions()
                }
                
                Button("Cancel", role: .cancel) {
                    pendingDeleteOffsets = []
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                reloadViewModel()
                reloadData()
            }
        }
    }
    
    // MARK: - Total Balance
    
    private var collapsedMonthlyBalanceCard: some View {
        
        HStack {
            HStack(alignment: .center, spacing: 10) {
                Text("Nov 2026")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 8)
                
                Text(currency(monthlyResult))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(
                        monthlyResult >= 0 ? .green : .red
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var totalBalanceCard: some View {
        HStack {
            HStack(alignment: .center, spacing: 10) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 8)
                        
                Text(currency(totalBalance))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(
                        totalBalance >= 0 ? .green : .red
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.04),
                            Color.green.opacity(0.13)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.8))
        }
    }
    
    // MARK: - Search & Filter
    
    private var searchAndFilter: some View {
        HStack(spacing: 10) {
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search transactions...", text: $searchText)
                    .font(.subheadline)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: Capsule()
            )
            
            Menu {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .background(.white, in: Circle())
            }
            .accessibilityLabel("Filter transactions")
        }
    }
    
    // MARK: - Transactions
    
    private var transactionsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(groupedTransactions) { group in
                VStack(spacing: 0) {
                    
                    groupHeader(group)
                    
                    VStack(spacing: 0) {
                        ForEach(group.transactions) { tx in
                            transactionRow(tx)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTransaction(tx)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            
                            Divider()
                                .padding(.leading, 56)
                        }
                        .background(
                            .white,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                }
            }
        }
        .accessibilityIdentifier("transactions-list")
    }
    
    private func groupHeader(_ group: TransactionGroup) -> some View {
        HStack {
            Text(group.date, format: grouping == .day
                 ? .dateTime.day().month(.wide).year()
                 : .dateTime.month(.wide).year())
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(currency(group.balance))
                .font(.caption.weight(.medium))
                .foregroundStyle(
                    group.balance >= 0 ? .green : .red
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Color.blue.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .padding(.bottom, 4)
    }
    
    private func transactionRow(_ tx: Transaction) -> some View {
        NavigationLink {
            
            let config = TransactionFormConfig(
                transaction: tx,
                crudOperation: .update,
                categories: viewModel.categories,
                accounts: viewModel.accounts
            )
            
            TransactionFormView(config: config) {
                handleResult(result: $0)
            }
        } label: {
            HStack(spacing: 12) {
                
                Image(systemName: tx.category.imageName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 36, height: 36)
                    .background(Color(rgbaCsv: tx.category.rgbColor),
                        in: Circle()
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.category.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let detail = tx.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 8)
                
                Text(currency(tx.amount))
                    .font(.subheadline)
                    .foregroundStyle(tx.isExpense ? .red : .green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteTransaction(tx)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
        
    // MARK: - Helpers
    
    private func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "ARS"))
    }
    
    private func deleteTransaction(_ tx: Transaction) {
        if let index = viewModel.transactions.firstIndex(where: { $0.id == tx.id }) {
            pendingDeleteOffsets = IndexSet(integer: index)
        }
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
    
    private func deletePendingTransactions() {
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
    
    private func reloadViewModel() {
        Task {
            do {
                try await viewModel.reload()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func reloadData() {
        Task {
            await viewModel.reloadCategories()
            await viewModel.reloadAccounts()
        }
    }
    
    private func handleResult(result: TransactionFormResult) {
        switch result {
            
        case .created(let date, let category, let detail,
                      let type, let account, let amount):
            
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
}

// MARK: - Supporting Types

private enum TransactionFilter: String, CaseIterable, Identifiable {
    case all
    case income
    case expenses
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: "All transactions"
        case .income: "Income"
        case .expenses: "Expenses"
        }
    }
}

private struct TransactionGroup: Identifiable {
    let date: Date
    let transactions: [Transaction]
    
    var id: Date { date }
    
    var balance: Decimal {
        transactions.reduce(Decimal.zero) { result, tx in
            result + (tx.isExpense ? -tx.amount : tx.amount)
        }
    }
}

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    let vm = cf.transactionsViewModel(
        dataStore: cf.dataStore()
    ) as! DefaultTransactionsViewModel
    
    TransactionsView<DefaultTransactionsViewModel>(viewModel: vm)
}

