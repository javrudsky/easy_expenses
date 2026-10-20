//
//  ImportTransactionsView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 20/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportTransactionsView: View {
    @State private var showingFileImporter = false
    @State private var selectedFile: URL?
    @State private var importError: String?
    @State private var showingError = false

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

                    Text(selectedFile?.lastPathComponent ?? "Select a CSV file")
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

                if selectedFile != nil {
                    Button {
                        // Validate, preview and import the selected CSV.
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
                }

                DataInfoBox(
                    icon: "info.circle",
                    title: "Before importing",
                    message: "Review your transactions before adding them. Argi will check the file for errors and possible duplicates."
                )
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
                selectedFile = url
            case .failure(let error):
                importError = error.localizedDescription
                showingError = true
            }
        }
        .alert("Unable to Open File", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "An unknown error occurred.")
        }
    }
}
