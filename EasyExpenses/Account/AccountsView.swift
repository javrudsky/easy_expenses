import SwiftUI
import SwiftData

struct AccountsView<VM: AccountsViewModel>: View {
    @ObservedObject var viewModel: VM
    @State private var editingName: [UUID: String] = [:]
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

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
                        save(account)
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
            .onDelete { offsets in
                delete(offsets: offsets)
            }
        }
        .alert("Unable to complete", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
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
                errorMessage = "You can’t delete this account while it has associated transactions. Remove or move those transactions first."
                showingError = true
            }
        }
    }
    
    private func save(_ account: Account) {
        let updated = Account(id: account.id, name: editingName[account.id] ?? account.name)
        Task {
            do {
                try await viewModel.save(updated)
            } catch {
                errorMessage = "We couldn’t save your changes. Please try again."
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
