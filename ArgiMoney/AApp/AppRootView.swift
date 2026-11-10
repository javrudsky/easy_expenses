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
            try? createAudioRecordingView(dataStore: dataStore)
                .tabItem { Label("Record", systemImage: "mic") }
            
            try? createTransactionsView(dataStore: dataStore)
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
            
            createReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
            
            MoreView(appFactory: af,
                     viewFactory: DefaultViewFactory(),
                     dataStore: dataStore)
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
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
    
    private func createReportsView() -> some View {
        return ReportsView()
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

