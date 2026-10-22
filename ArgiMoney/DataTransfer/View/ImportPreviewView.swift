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
                    countsBubble(summary: summary)
                    issuesBubble(summary: summary)
                }

                logSection

                HStack(spacing: 12) {
                    Button(role: .cancel) { onCancel() } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ArgiColors.primaryText)
                    .background(ArgiColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        onProceed()
                    } label: {
                        Text(viewModel.canProceed ? "Proceed" : "Proceed Anyway")
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

    private func countsBubble(summary: ImportSummary) -> some View {
        VStack(spacing: 12) {
            HStack {
                bubbleItem(icon: "list.bullet", title: "Transactions", value: "\(summary.transactions.count)")
                Spacer()
                bubbleItem(icon: "folder", title: "Categories", value: "\(summary.categories.count)")
                Spacer()
                bubbleItem(icon: "creditcard", title: "Accounts", value: "\(summary.accounts.count)")
            }
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
                HStack(spacing: 14) {
                    bubbleItem(icon: "xmark.octagon.fill", title: "Errors", value: "\(errors)", color: Color.red)
                    Spacer()
                    bubbleItem(icon: "exclamationmark.triangle.fill", title: "Warnings", value: "\(warnings)", color: Color.orange)
                }
                Text("There were issues found in your file. You can proceed, but some items may be skipped or need attention.")
                    .font(.subheadline)
                    .foregroundStyle(ArgiColors.secondaryText)
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ArgiColors.green)
                    Text("Everything looks good! You're ready to import.")
                        .foregroundStyle(ArgiColors.secondaryText)
                }
                .font(.subheadline)
            }
        }
        .padding(18)
        .background(hasIssues ? Color.red.opacity(0.06) : Color.green.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func bubbleItem(icon: String, title: String, value: String, color: Color = ArgiColors.blue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .foregroundStyle(ArgiColors.secondaryText)
            }
            Text(value)
                .font(.headline)
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log")
                .font(.headline)

            ScrollView {
                Text(viewModel.importLog.isEmpty ? "No log available." : viewModel.importLog)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(ArgiColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(minHeight: 120)
        }
    }
}
