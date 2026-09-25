import SwiftUI
import SwiftData

struct AppRootView: View {
    
    let af: AppFactory
    let transactionRepo: TransactionRepository
    
    init(appFactory: AppFactory) {
        //_viewModel = StateObject(wrappedValue: di.makeTransactionsViewModel())
        self.af = appFactory
        self.transactionRepo = appFactory.createTransactionRepository()
    }
    
    var body: some View {
        TabView {
            try? createAudioRecordingView(repo: self.transactionRepo)
                .tabItem { Label("Record", systemImage: "mic") }
            
            try? createTransactionsView(repo: self.transactionRepo)
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
            
            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
            
            MoreView(appFactory: af)
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
       
    private func createAudioRecordingView(repo: TransactionRepository) throws -> AudioRecordingView<DefaultAudioRecordingViewModel> {
        if let vm = af.createAudioRecordingViewModel(repo: repo) as? DefaultAudioRecordingViewModel {
            return AudioRecordingView<DefaultAudioRecordingViewModel>(viewModel: vm)
        }
        throw ViewError.couldNotCreateView
    }
    
    private func createTransactionsView(repo: TransactionRepository) throws -> TransactionsView<DefaultTransactionsViewModel> {
        if let vm = af.createTransactionsViewModel(repo: repo) as? DefaultTransactionsViewModel {
            return TransactionsView<DefaultTransactionsViewModel>(viewModel: vm)
        }
        // This should never happen
        throw ViewError.couldNotCreateView
    }
}

#Preview {
    let af = try! DefaultAppFactory(modelContainer: try! DefaultAppFactory.createModelContainer(inMemory: true))
    AppRootView(appFactory: af)
}


    
struct ReportsView: View {
    var body: some View {
        Text("Reports")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
}

struct MoreView: View {
    let af: AppFactory
    init(appFactory: AppFactory) {
        self.af = appFactory
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Management") {
                    NavigationLink { try? createCategoriesView() } label: { Label("Categories", systemImage: "square.grid.2x2") }
                    NavigationLink { try? createAccountsView() } label: { Label("Accounts", systemImage: "creditcard") }
                }
                Section("Insights") {
                    NavigationLink { ReportsView() } label: { Label("Reports", systemImage: "chart.bar") }
                }
            }
            .navigationTitle("More")
        }
    }
    
    private func createCategoriesView() throws -> CategoriesView<DefaultCategoriesViewModel> {
         if let vm = af.createCategoriesViewModel() as? DefaultCategoriesViewModel {
            return CategoriesView<DefaultCategoriesViewModel>(viewModel: vm)
        }
        // This should never happen
        throw ViewError.couldNotCreateView
        }
    
    private func createAccountsView() throws  -> AccountsView<DefaultAccountsViewModel> {
        if let vm = af.createAccountsViewModel() as? DefaultAccountsViewModel {
            return AccountsView<DefaultAccountsViewModel>(viewModel: vm)
        }
        // This should never happen
        throw ViewError.couldNotCreateView
    }

}
