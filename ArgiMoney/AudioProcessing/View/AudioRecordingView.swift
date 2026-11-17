import Foundation
import SwiftUI

struct AudioRecordingView<VM: AudioRecordingViewModel>: View {
    @StateObject private var viewModel: VM
    @Environment(\.theme) private var theme

    // Purely UI state
    @State private var pulse = false
    @State private var dragOffset: CGSize = .zero
    @State private var willCancel = false
    @State private var errorMessage = ""
    @State private var showingError = false

    // Scales with Dynamic Type instead of screen width
    @ScaledMetric(relativeTo: .largeTitle) private var micSize: CGFloat = 150

    private let cancelThreshold: CGFloat = 100

    init(viewModel: VM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
           
            MonthlyBalanceView(incomeAmount: viewModel.totals.income,
                               expensesAmount: viewModel.totals.expenses,
                               resultAmount: viewModel.totals.result,
                               showingDetail: true)

            characterCard

            Text(assistentMsg(isRec: viewModel.isRecording))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            micButton

            Text(recBottonMsg(isRec: viewModel.isRecording))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .onAppear { reloadTotals() }
        .sheet(isPresented: $viewModel.showTransactionForm, onDismiss: reloadTotals) {
            buildTransactionFormView()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    private var characterCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(theme.cardBackground)
                .offset(y: -14)

            Image(viewModel.isRecording ? "argi_listening" : "argi_waiting")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 280)
    }

    private var micButton: some View {
        ZStack {
            Circle()
                .fill(viewModel.isRecording ? theme.micRecordingBackground : theme.micIdleBackground)
                .frame(width: micSize, height: micSize)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .animation(
                    viewModel.isRecording
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )

            Circle()
                .fill(viewModel.isRecording ? theme.accentNegative : theme.brandPrimary)
                .frame(width: micSize * 0.875, height: micSize * 0.875)

            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: micSize * 0.3, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: micSize, height: micSize)
        .accessibilityLabel(viewModel.isRecording ? "Recording in progress" : "Not recording")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Press and hold to start recording. Slide left or right to cancel. Release to stop.")
        .onChange(of: viewModel.isRecording) { _, recording in
            pulse = recording
        }
        .gesture(recordGesture)
        .offset(x: viewModel.isRecording ? dragOffset.width * 0.15 : 0)
    }

    private var recordGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !viewModel.isRecording {
                    viewModel.startRecording()
                }
                dragOffset = value.translation
                willCancel = abs(dragOffset.width) > cancelThreshold
            }
            .onEnded { _ in
                if viewModel.isRecording {
                    willCancel ? viewModel.cancelRecording() : viewModel.stopRecording()
                }
                dragOffset = .zero
                willCancel = false
            }
    }

    // MARK: - Helpers (unchanged)

    private func assistentMsg(isRec: Bool) -> String {
        isRec ? String(localized: "I'm listening") : String(localized: "Tell me about your transaction")
    }

    private func recBottonMsg(isRec: Bool) -> String {
        isRec ? String(localized: "Drag left / right to cancel") : String(localized: "Hold to record")
    }

    private func reloadTotals() {
        Task { await viewModel.reloadTotals() }
    }

    private func buildTransactionFormView() -> TransactionFormView {
        let config = TransactionFormConfig(transaction: viewModel.pendingTransaction,
                                           crudOperation: .create,
                                           categories: viewModel.categories,
                                           accounts: viewModel.accounts)
        return TransactionFormView(config: config, isPresented: true) { handleTransactionResult(result: $0) }
    }

    private func handleTransactionResult(result: TransactionFormResult) {
        switch result {
        case .created(let date, let category, let detail, let type, let account, let amount):
            let builder = TransactionBuilder()
                .setting(date: date.timeIntervalSince1970)
                .setting(type: type)
                .setting(category: category)
                .setting(account: account)
                .setting(amount: amount)
                .setting(detail: detail)
            Task {
                do {
                    try await viewModel.insertTransaction(builder: builder)
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        default:
            print("Update tx?")
        }
    }
}
