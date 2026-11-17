import SwiftUI
import SwiftData

struct AppRootView: View {
    
    private let af: AppFactory
    private let dataStore: DataStore
    @Environment(\.theme) var theme: Theme
    
    init(appFactory: AppFactory) {
        //_viewModel = StateObject(wrappedValue: di.makeTransactionsViewModel())
        self.af = appFactory
        self.dataStore = appFactory.dataStore()
        self.setupDefaultsIfNeeded()
    }
    
    var body: some View {
        TabView {
            Tab("Record", systemImage: "mic") {
                try? createAudioRecordingView(dataStore: dataStore)
            }
            
            Tab("Transactions", systemImage: "list.bullet.rectangle")  {
                try? createTransactionsView(dataStore: dataStore)
            }
            
            Tab("Reports", systemImage: "chart.bar") {
                createReportsView(dataStore: dataStore)
            }
            
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
            
            Tab("More", systemImage: "ellipsis.circle") {
                MoreView(appFactory: af,
                         viewFactory: DefaultViewFactory(),
                         dataStore: dataStore)
            }
        }
        .onAppear {
            ThemeManager.shared.setTheme(af.appValues().theme())
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
    
    private func createReportsView(dataStore: DataStore) -> ReportsView<DefaultReportsViewModel> {
        return ReportsView<DefaultReportsViewModel>(dataStore: dataStore)
    }
}

#Preview {
    let af = try! DefaultAppFactory(modelContainer: try! DefaultAppFactory.createModelContainer(inMemory: true))
    #if PREMIUM
    let purchaseService = StoreKitPurchaseService()
    #else
    let purchaseService = MockPurchaseService()
    #endif
    AppRootView(appFactory: af)
        .environment(FeatureAccessManager(service: purchaseService))
}

