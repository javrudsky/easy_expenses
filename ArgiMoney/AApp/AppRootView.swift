import SwiftUI
import SwiftData

struct AppRootView: View {
    
    let af: AppFactory
    let dataStore: DataStore
    
    init(appFactory: AppFactory) {
        //_viewModel = StateObject(wrappedValue: di.makeTransactionsViewModel())
        self.af = appFactory
        self.dataStore = appFactory.dataStore()
        self.setupDefaultsIfNeeded()
    }
    
    var body: some View {
        TabView {
            try? createAudioRecordingView(dataStore: dataStore)
                .tabItem { Label("Record", systemImage: "mic") }
            
            try? createTransactionsView(dataStore: dataStore)
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
            
            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
            
            MoreView(appFactory: af, dataStore: dataStore)
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
       
    private func setupDefaultsIfNeeded() {
        let av = af.appValues()
        if av.getAndUpdateIsFirstRun() {
            Task {
                await dataStore.categoryRepo.insert(AppDefaults.defaultCategories)
                try? await dataStore.accountRepo.insertOrUpdate(AppDefaults.account)
            }
        }
    }
    private func createAudioRecordingView(dataStore: DataStore) throws -> AudioRecordingView<DefaultAudioRecordingViewModel> {
        if let vm = af.audioRecordingViewModel(dataStore: dataStore) as? DefaultAudioRecordingViewModel {
            return AudioRecordingView<DefaultAudioRecordingViewModel>(viewModel: vm)
        }
        throw ViewError.couldNotCreateView
    }
    
    private func createTransactionsView(dataStore: DataStore) throws -> TransactionsView<DefaultTransactionsViewModel> {
        if let vm = af.transactionsViewModel(dataStore: dataStore) as? DefaultTransactionsViewModel {
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
    let dataStore: DataStore
    init(appFactory: AppFactory,
         dataStore: DataStore) {
        self.af = appFactory
        self.dataStore = dataStore
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Management") {
                    NavigationLink { createDataManagementView() } label: { Label("Import/Export", systemImage: "square.grid.2x2") }
                    NavigationLink { try? createCategoriesView(transactionType: .expense) } label: { Label("Expense Categories", systemImage: "square.grid.2x2") }
                    NavigationLink { try? createCategoriesView(transactionType: .income) } label: { Label("Income Categories", systemImage: "square.grid.2x2") }
                    NavigationLink { try? createAccountsView() } label: { Label("Accounts", systemImage: "creditcard") }
                }
                Section("Insights") {
                    NavigationLink { ReportsView() } label: { Label("Reports", systemImage: "chart.bar") }
                }
            }
            .navigationTitle("More")
        }
    }
    
    private func createCategoriesView(transactionType: TransactionType) throws -> CategoriesView<DefaultCategoriesViewModel> {
        if let vm = af.categoriesViewModel(transactionType: transactionType,
                                            dataStore: dataStore) as? DefaultCategoriesViewModel {
            return CategoriesView<DefaultCategoriesViewModel>(viewModel: vm)
        }
        // This should never happen
        throw ViewError.couldNotCreateView
        }
    
    private func createAccountsView() throws  -> AccountsView<DefaultAccountsViewModel> {
        if let vm = af.accountsViewModel(dataStore: dataStore) as? DefaultAccountsViewModel {
            return AccountsView<DefaultAccountsViewModel>(viewModel: vm)
        }
        // This should never happen
        throw ViewError.couldNotCreateView
    }
    
    private func createDataManagementView() -> DataManagementView {
        return DataManagementView(factory: af, dataStore: dataStore)
    }
}
