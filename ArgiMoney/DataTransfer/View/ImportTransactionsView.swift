//
//  ImportTransactionsView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 20/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportTransactionsView<VM: ImportTransactionsViewModel>: View {
    @ObservedObject private var viewModel: VM
    @State private var showingFileImporter = false
    @State private var showingError = false
    @State private var isShowingPreview = false

    init(viewModel: VM) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 18) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 34))
                        .foregroundStyle(ArgiColors.green)
                        .frame(width: 88, height: 88)
                        .background(ArgiColors.green.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Import Transactions")
                            .font(.title3.bold())

                        Text("Import transactions from a CSV file.")
                            .font(.subheadline)
                            .foregroundStyle(ArgiColors.secondaryText)
                    }
                }

                VStack(spacing: 14) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 42))
                        .foregroundStyle(ArgiColors.green)

                    Text(viewModel.selectedFile?.lastPathComponent ?? "Select a CSV file")
                        .font(.headline)
                        .lineLimit(2)

                    Text("Choose a CSV file from Files or iCloud Drive.")
                        .font(.subheadline)
                        .foregroundStyle(ArgiColors.secondaryText)
                        .multilineTextAlignment(.center)

                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Choose File", systemImage: "folder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(ArgiColors.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(ArgiColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 22))

                if viewModel.selectedFile != nil {
                    Button {
                        Task {
                            do {
                                let _ = try await viewModel.importCsv()
                                isShowingPreview = true
                                // TODO: Navigate to preview using the returned summary
                            } catch {
                                showingError = true
                            }
                        }
                    } label: {
                        Text("Continue to Preview")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(ArgiColors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(viewModel.isImporting)
                }

                DataInfoBox(
                    icon: "info.circle",
                    title: "Before importing",
                    message: "Review your transactions before adding them. Argi will check the file for errors and possible duplicates."
                )
                
                NavigationLink(isActive: $isShowingPreview) {
                    ImportPreviewView(viewModel: viewModel,
                                      onCancel: { isShowingPreview = false },
                                      onProceed: {
                                          Task { try? await viewModel.proceedImport() }
                                      })
                } label: { EmptyView() }
                .hidden()
            }
            .padding(20)
        }
        .background(ArgiColors.background)
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            switch result {
            case .success(let url):
                viewModel.setSelectedFile(url)
            case .failure(let error):
                viewModel.lastError = error.localizedDescription
                showingError = true
            }
        }
        .alert("Unable to Open File", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.lastError ?? "An unknown error occurred.")
        }
    }
}

