import SwiftUI

struct AudioRecordingView<VM: AudioRecordingViewModel>: View {
    @StateObject private var viewModel: VM

    // Purely UI state
    @State private var pulse: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var willCancel: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false

    init(viewModel: VM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Main feedback widget
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? Color.red.opacity(0.25) : Color.gray.opacity(0.15))
                    .frame(width: 180, height: 180)
                Circle()
                    .stroke(lineWidth: 6)
                    .fill(viewModel.isRecording ? Color.red : Color.gray)
                    .frame(width: pulse ? 170 : 150, height: pulse ? 170 : 150)
                    .animation(viewModel.isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: pulse)
                Image(systemName: viewModel.isRecording ? "waveform" : "mic")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(viewModel.isRecording ? .red : .secondary)
            }
            .accessibilityLabel(viewModel.isRecording ? "Recording in progress" : "Not recording")
            .onChange(of: viewModel.isRecording) { _, recording in
                if recording {
                    pulse.toggle()
                } else {
                    pulse = false
                }
            }

            // Transcription output
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription")
                    .font(.headline)
                Text(viewModel.latestText.isEmpty ? "Hold to record and speak…" : viewModel.latestText)
                    .font(.body)
                    .foregroundStyle(viewModel.isFinal ? .primary : .secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            // Press-and-hold record button
            Text(viewModel.isRecording ? (willCancel ? "Slide to Cancel" : "Release to Stop") : "Hold to Record")
                    .font(.headline)
                    .frame(width: 150)
                    .frame(height: 150)
                    .background((viewModel.isRecording && willCancel) ? Color.red : (viewModel.isRecording ? Color.accentColor : Color.green), in: Capsule())
                    .foregroundStyle(.white)
                    .contentShape(Capsule())
            .padding(.horizontal)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !viewModel.isRecording {
                            viewModel.startRecording()
                        }
                        dragOffset = value.translation
                        let cancelThreshold: CGFloat = 100
                        willCancel = abs(dragOffset.width) > cancelThreshold
                    }
                    .onEnded { _ in
                        if viewModel.isRecording {
                            if willCancel {
                                viewModel.cancelRecording()
                            } else {
                                viewModel.stopRecording()
                            }
                        }
                        dragOffset = .zero
                        willCancel = false
                    }
            )
            .offset(x: viewModel.isRecording ? dragOffset.width * 0.15 : 0)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Press and hold to start recording. Slide left or right to cancel. Release to stop.")

            Spacer()
        }
        .padding()
        .sheet(isPresented: $viewModel.showTransactionForm) {
            TransactionFormView(crudOperation: .create, transaction: viewModel.pendingTransaction) { result in
                // Handle form result if needed; could call into another VM method
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
        .alert("Error", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage)
        })

    }
}

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    let vm = DefaultAudioRecordingViewModel(analyzer: cf.createAudioTranscriber(),
                                     inputParser: cf.createInputParser(),
                                     transactionRepo: cf.createTransactionRepository())
    AudioRecordingView<DefaultAudioRecordingViewModel>(viewModel: vm)
}
