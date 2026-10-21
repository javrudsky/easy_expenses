//
//  ExportTransactionsView.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 20/10/2026.
//

import SwiftUI

enum DateRange {
    case currentMonth
    case currentYear
    case custom
    case all
    
    var description: String {
        switch self {
        case .currentMonth:
            return "This Month"
        case .currentYear:
            return "This Year"
        case .custom:
            return "Custom Range"
        case .all:
            return "All time"
        }
    }
}

struct ExportTransactionsView<VM: ExportTransactionsViewModel>: View {
   
    @ObservedObject private var viewModel: VM
   
    init(viewModel: VM) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                
                VStack(spacing: 0) {
                    Menu {
                        Button(DateRange.all.description) { viewModel.selectedRange = .all }
                        Button(DateRange.currentMonth.description) { viewModel.selectedRange = .currentMonth }
                        Button(DateRange.currentYear.description) { viewModel.selectedRange = .currentYear }
                        Button(DateRange.custom.description) { viewModel.selectedRange = .custom }
                    } label: {
                        selectionRow("Date range", value: viewModel.selectedRange)
                    }
                    
                    Divider()
                    
                    if viewModel.selectedRange == .custom {
                        HStack {
                            Text("From")
                            DatePicker("", selection: $viewModel.fromDate, displayedComponents: [.date])
                            Text("To")
                            DatePicker("", selection: $viewModel.toDate, displayedComponents: [.date])
                        }
                    }
                }
                .background(ArgiColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                exportSummary
                
                if let url = viewModel.exportURL {
                    ShareLink(item: url) {
                        Label("Export & Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(ArgiColors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Button {
                       exportToCsv()
                    } label: {
                        HStack {
                            if viewModel.isExporting {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Text(viewModel.isExporting ? "Preparing..." : "Export & Share")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(ArgiColors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(viewModel.isExporting)
                }
                
                DataInfoBox(
                    icon: "info.circle",
                    title: "Save or share",
                    message: "Choose where to save or share your file, including Files, Mail, AirDrop and more."
                )
                
                Divider()
                
                HStack(spacing: 14) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundStyle(ArgiColors.green)
                        .frame(width: 48, height: 48)
                        .background(ArgiColors.green.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open in Numbers")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("The exported CSV file can be opened in Numbers, Excel and Google Sheets.")
                            .font(.caption)
                            .foregroundStyle(ArgiColors.secondaryText)
                    }
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $viewModel.isShareSheetVisible) {
            if let url = viewModel.exportURL {
                ShareLink(item: url,
                          preview: SharePreview("transactions.cvs", image: Image(systemName: "doc.text")))
            }
        }
        .alert(
            "Export Failed",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .background(ArgiColors.background)
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 34))
                .foregroundStyle(ArgiColors.blue)
                .frame(width: 88, height: 88)
                .background(ArgiColors.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Export Transactions")
                    .font(.title3.bold())
                
                Text("Create a CSV file with your transactions to save or share.")
                    .font(.subheadline)
                    .foregroundStyle(ArgiColors.secondaryText)
            }
        }
    }
    
    private func selectionRow(_ title: String, value: DateRange) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(ArgiColors.primaryText)
            
            Spacer()
            
            Text(value.description)
                .foregroundStyle(ArgiColors.secondaryText)
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .contentShape(Rectangle())
    }
    
    private var exportSummary: some View {
        VStack(spacing: 16) {
            summaryRow("Transactions", value: "248", icon: "doc")
            if viewModel.selectedRange == .custom {
                let summaryText = "\(viewModel.fromDate.uiFormat) to \(viewModel.toDate.uiFormat)"
                summaryRow("Date range", value: summaryText, icon: "calendar")
            } else {
                summaryRow("Date range", value: viewModel.selectedRange.description, icon: "calendar")
            }
            summaryRow("File name", value: "argi-transactions.csv", icon: "tag")
        }
        .padding(20)
        .background(ArgiColors.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func summaryRow(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(ArgiColors.secondaryText)
            
            Text(title)
                .foregroundStyle(ArgiColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.subheadline)
    }
    
    private func exportToCsv() {
        Task {
            await viewModel.exportToCsv()
        }
    }
}
