//
//  ImportExportView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 20/10/2026.
//
import SwiftUI

struct DataManagementView: View {
    let af: AppFactory
    let ds: DataStore
    init(factory: AppFactory,
         dataStore: DataStore) {
        af = factory
        ds = dataStore
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Import & Export")
                            .font(.largeTitle.bold())

                        Text("Create a backup of your data or import transactions from a CSV file.")
                            .font(.subheadline)
                            .foregroundStyle(ArgiColors.secondaryText)
                    }
                    .padding(.bottom, 12)

                    NavigationLink {
                        try? createExportTransactionsView()
                    } label: {
                        DataFeatureCard(
                            title: "Export",
                            subtitle: "Create a CSV file with your transactions to save or share.",
                            icon: "square.and.arrow.up",
                            color: ArgiColors.blue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ImportTransactionsView()
                    } label: {
                        DataFeatureCard(
                            title: "Import",
                            subtitle: "Add transactions from a CSV file to your account.",
                            icon: "square.and.arrow.down",
                            color: ArgiColors.green
                        )
                    }
                    .buttonStyle(.plain)

                    DataInfoBox(
                        icon: "checkmark.shield",
                        title: "Your data stays on your device",
                        message: "Import and export files are created and processed locally. We never send your financial data to our servers."
                    )
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(ArgiColors.background)
            .navigationTitle("Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createExportTransactionsView() throws -> ExportTransactionsView<DefaultExportTransactionsViewModel> {
        if let vm = af.exportTransactionsViewModel(dataStore: ds) as? DefaultExportTransactionsViewModel {
            return ExportTransactionsView<DefaultExportTransactionsViewModel>(viewModel: vm)
        }
        throw ViewError.couldNotCreateView
    }
}
