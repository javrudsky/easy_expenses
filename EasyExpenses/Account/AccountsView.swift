import SwiftUI
import SwiftData

struct AccountsView<VM: AccountsViewModel>: View {
    @State private var showingError: Bool = false
    @ObservedObject var viewModel: VM
    @State private var editingName: [UUID: String] = [:]

    var body: some View {
        List {
            ForEach(viewModel.accounts) { account in
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundStyle(.secondary)
                    TextField("Name", text: Binding(
                        get: { editingName[account.id] ?? account.name },
                        set: { editingName[account.id] = $0 }
                    ), onCommit: {
                        let updated = Account(id: account.id, name: editingName[account.id] ?? account.name)
                        Task { await viewModel.save(updated) }
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
            .onDelete { offsets in
                delete(offsets: offsets)
            }
        }
        .alert("Message", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text("Couldn't delete because in transactions")
            })
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.add() }) {
                    Label("Add Account", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Accounts")
    }

    private func delete(offsets: IndexSet) {
        Task {
            do {
                try await viewModel.delete(at: offsets)
            } catch {
                showingError = true
            }
        }
    }
}

#Preview {
    let repo = SwiftDataAccountRepository(modelContainer: try! DefaultAppFactory.createModelContainer(inMemory: true))
    let vm = DefaultAccountsViewModel(repo: repo)
    AccountsView(viewModel: vm)
}
