import SwiftUI
import Combine

struct ImportPreviewView<VM: ImportTransactionsViewModel>: View {
    @ObservedObject var viewModel: VM

    let onCancel: () -> Void
    let onProceed: () -> Void

    init(viewModel: VM,
         onCancel: @escaping () -> Void,
         onProceed: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCancel = onCancel
        self.onProceed = onProceed
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let summary = viewModel.summary {
                    countsBubble(summary: ProcessedSummary(summary: summary))
                    issuesBubble(summary: summary)
                }

                logSection

                HStack(spacing: 12) {
                    Button {
                        onProceed()
                    } label: {
                        Text(viewModel.areIssues ? "Proceed" : "Proceed Anyway")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(ArgiColors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(viewModel.isImporting)
                }
            }
            .padding(20)
        }
        .background(ArgiColors.background)
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 18) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(ArgiColors.blue)
                .frame(width: 88, height: 88)
                .background(ArgiColors.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 8) {
                Text("Review Import")
                    .font(.title3.bold())

                Text("Check counts, issues and the log before proceeding.")
                    .font(.subheadline)
                    .foregroundStyle(ArgiColors.secondaryText)
            }
        }
    }

    struct ProcessedSummary {
        let tc: Int
        let dup: Int
        let imp: Int
        let cat: Int
        let acc: Int
        init(summary: ImportSummary) {
            tc = summary.transactions.count
            dup = summary.duplicatedTransactions.count
            imp = tc - dup
            cat = summary.categories.count
            acc = summary.accounts.count
        }
    }
    
    private func countsBubble(summary: ProcessedSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Grid {
                bubbleItem(icon: "list.bullet", title: "Transactions", value: "\(summary.tc)")
                Spacer()
                bubbleItem(icon: "document.on.document", title: "Duplicates", value: "\(summary.dup)")
                Spacer()
                bubbleItem(icon: "arrow.down.square", title: "Importing", value: "\(summary.imp)")
                Spacer()
                bubbleItem(icon: "folder", title: "Categories", value: "\(summary.cat)")
                Spacer()
                bubbleItem(icon: "creditcard", title: "Accounts", value: "\(summary.acc)")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(ArgiColors.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func issuesBubble(summary: ImportSummary) -> some View {
        let errors = summary.logSummary.errorCount
        let warnings = summary.logSummary.warningCount
        let hasIssues = (errors + warnings) > 0
        return VStack(alignment: .leading, spacing: 10) {
            if hasIssues {
                Grid {
                    bubbleItem(icon: "xmark.octagon.fill", title: "Errors", value: "\(errors)", color: Color.red)
                    Spacer()
                    bubbleItem(icon: "exclamationmark.triangle.fill", title: "Warnings", value: "\(warnings)", color: Color.orange)
                }
                .frame(maxWidth: .infinity)
                
                Text("There were issues found in your file. You can proceed, but some items may be skipped or need attention.")
                    .font(.subheadline)
                    .foregroundStyle(ArgiColors.secondaryText)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Everything looks good! You're ready to import.")
                        .foregroundStyle(ArgiColors.secondaryText)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)

            }
        }
        .padding(18)
        .background(hasIssues ? Color.red.opacity(0.06) : Color.green.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func bubbleItem(icon: String, title: String, value: String, color: Color = ArgiColors.blue) -> some View {
        
        GridRow {
            Image(systemName: icon)
                .foregroundStyle(color)
                .gridColumnAlignment(.leading)
//                .gridCellAnchor(UnitPoint(x: 0.1, y: 0.5))
            Text(title)
                .foregroundStyle(ArgiColors.secondaryText)
                .gridColumnAlignment(.leading)
            Text(value)
            .font(.headline)
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log")
                .font(.headline)

            ScrollView([.vertical, .horizontal]) {
                Text(currentLog())
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .lineSpacing(2)
                    .foregroundStyle(ArgiColors.secondaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(12)
                    .background(ArgiColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(minHeight: 120)
        }
    }
    
    func currentLog() -> String {
        guard let log = viewModel.summary?.logSummary.log else {
            return "No log available"
        }
        
        if log.isEmpty {
            return "The log is empty"
        }
        return log
    }
}

