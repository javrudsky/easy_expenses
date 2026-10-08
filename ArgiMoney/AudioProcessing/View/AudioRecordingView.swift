import SwiftUI

struct CornerRadiusStyle: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = [.allCorners]

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct VV {
    static let charBgOffset: Double = -14.0
}

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
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            VStack(spacing: w * 0.02) {

                VStack {
                    SummaryCard(income: 10, expenses: 200)
                    
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: h * 0.10)
                    
                    Spacer()
                        .frame(height: h * 0.07)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 50.0)
                            .fill(Color.blue.opacity(0.10))
                            .offset(y: VV.charBgOffset)
                        
                        Image(viewModel.isRecording ?  "argi_listening" : "argi_waiting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: w * 0.80, alignment: .bottom)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: h * 0.30)
                }
                
                Text("Tell Argi about your transaction")
                    .font(.system(size: w * 0.04, weight: .semibold))
                    .foregroundStyle(.gray)

                Spacer()
                        .frame(height: h * 0.07)

                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red.opacity(0.20) : Color.blue.opacity(0.15))
                        .frame(width: w * 0.40, height: w * 0.40)
                    
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: w * 0.35, height: w * 0.35)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: w * 0.12, weight: .semibold))
                        .foregroundStyle(.white)
                    
                }
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

                Text("Hold to record")
                    .font(.system(size: w * 0.04, weight: .regular))
                    .foregroundStyle(.gray)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .sheet(isPresented: $viewModel.showTransactionForm) {
                buildTransactionFormView()
            }
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })
        }
        
        //                ZStack {
//                    Circle()
//                        .fill(viewModel.isRecording ? Color.red.opacity(0.25) : Color.gray.opacity(0.15))
//                        .frame(width: w * 0.45, height: w * 0.45)
//                    Circle()
//                        .stroke(lineWidth: 6)
//                        .fill(viewModel.isRecording ? Color.red : Color.gray)
//                        .frame(width: pulse ? w * 0.42 : w * 0.37, height: pulse ? w * 0.42 : w * 0.37)
//                        .animation(viewModel.isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: pulse)
//                    Image(systemName: viewModel.isRecording ? "waveform" : "mic")
//                        .font(.system(size: w * 0.12, weight: .semibold))
//                        .foregroundStyle(viewModel.isRecording ? .red : .secondary)
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//                .accessibilityLabel(viewModel.isRecording ? "Recording in progress" : "Not recording")
//                .onChange(of: viewModel.isRecording) { _, recording in
//                    if recording {
//                        pulse.toggle()
//                    } else {
//                        pulse = false
//                    }
//                }
//                

                
                // Press-and-hold record button
//                Text(viewModel.isRecording ? (willCancel ? "Slide to Cancel" : "Release to Stop") : "Hold to Record")
//                    .font(.headline)
//                    .frame(width: 150)
//                    .frame(height: 150)
//                    .background((viewModel.isRecording && willCancel) ? Color.red : (viewModel.isRecording ? Color.accentColor : Color.green), in: Capsule())
//                    .foregroundStyle(.white)
//                    .contentShape(Capsule())
//                    .padding(.horizontal)
//                    .gesture(
//                        DragGesture(minimumDistance: 0)
//                            .onChanged { value in
//                                if !viewModel.isRecording {
//                                    viewModel.startRecording()
//                                }
//                                dragOffset = value.translation
//                                let cancelThreshold: CGFloat = 100
//                                willCancel = abs(dragOffset.width) > cancelThreshold
//                            }
//                            .onEnded { _ in
//                                if viewModel.isRecording {
//                                    if willCancel {
//                                        viewModel.cancelRecording()
//                                    } else {
//                                        viewModel.stopRecording()
//                                    }
//                                }
//                                dragOffset = .zero
//                                willCancel = false
//                            }
//                    )
//                    .offset(x: viewModel.isRecording ? dragOffset.width * 0.15 : 0)
//                    .accessibilityAddTraits(.isButton)
//                    .accessibilityHint("Press and hold to start recording. Slide left or right to cancel. Release to stop.")
//                
//                Spacer()
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//            .padding()
//            .sheet(isPresented: $viewModel.showTransactionForm) {
//                buildTransactionFormView()
//            }
//            .alert("Error", isPresented: $showingError, actions: {
//                Button("OK", role: .cancel) { }
//            }, message: {
//                Text(errorMessage)
//            })
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(.red))
//        .ignoresSafeArea()
    }
    
    private func buildTransactionFormView() -> TransactionFormView {
        let tran = viewModel.pendingTransaction
        let config = TransactionFormConfig(transaction: tran,
                                           crudOperation: .create,
                                           allCategories: viewModel.categories,
                                           gridCategories: viewModel.gridCategories(categories: viewModel.categories,
                                                                                    selected: tran?.category),
                                           accounts: viewModel.accounts)
        return TransactionFormView(config: config) { handleTransactionResult(result: $0)}
    }
    
    private func handleTransactionResult(result: TransactionFormResult) {
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

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    let fs = cf.transactionFormService(dataStore: cf.dataStore())
    let vm = DefaultAudioRecordingViewModel(analyzer: cf.createAudioTranscriber(),
                                            inputParser: cf.createInputParser(),
                                            formService: fs,
                                            dataStore: cf.dataStore(),
                                            appValues: cf.appValues())
    AudioRecordingView<DefaultAudioRecordingViewModel>(viewModel: vm)
}

