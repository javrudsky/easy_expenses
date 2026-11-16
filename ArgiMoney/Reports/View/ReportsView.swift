import SwiftUI

struct ReportsView<VM: ReportsViewModel>: View {
    @StateObject private var viewModel: VM
    private let embedInNavigationStack: Bool

    init(viewModel: VM,
         embedInNavigationStack: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.embedInNavigationStack = embedInNavigationStack
    }

    var body: some View {
        Group {
            if let dataset = viewModel.dataset {
                ReportMenuView(dataset: dataset,
                               embedInNavigationStack: embedInNavigationStack)
            } else if viewModel.isLoading {
                ProgressView("Loading reports…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("Unable to load reports",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(viewModel.errorMessage ?? "Add transactions to see reports."))
            }
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }
}

extension ReportsView where VM == DefaultReportsViewModel {
    @MainActor
    init(dataStore: DataStore,
         embedInNavigationStack: Bool = true) {
        self.init(viewModel: DefaultReportsViewModel(dataStore: dataStore),
                  embedInNavigationStack: embedInNavigationStack)
    }
}
