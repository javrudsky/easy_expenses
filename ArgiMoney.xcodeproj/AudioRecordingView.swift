import SwiftUI

struct AudioRecordingView: View {
    @State private var analyzer = AudioAnalyzer()
    @State private var isRecording = false
    @State private var latestText: String = ""
    @State private var isFinal: Bool = false
    @State private var pulse: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var willCancel: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            // Main feedback widget
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.25) : Color.gray.opacity(0.15))
                    .frame(width: 180, height: 180)
                Circle()
                    .stroke(lineWidth: 6)
                    .fill(isRecording ? Color.red : Color.gray)
                    .frame(width: pulse ? 170 : 150, height: pulse ? 170 : 150)
                    .animation(isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: pulse)
                Image(systemName: isRecording ? "waveform" : "mic")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(isRecording ? .red : .secondary)
            }
            .accessibilityLabel(isRecording ? "Recording in progress" : "Not recording")
            .onChange(of: isRecording) { _, recording in
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
                Text(latestText.isEmpty ? "Hold to record and speak…" : latestText)
                    .font(.body)
                    .foregroundStyle(isFinal ? .primary : .secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            // Press-and-hold record button
            Button(action: {}) {
                Text(isRecording ? (willCancel ? "Slide to Cancel" : "Release to Stop") : "Hold to Record")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background((isRecording && willCancel) ? Color.red : (isRecording ? Color.accentColor : Color.accentColor), in: Capsule())
                    .foregroundStyle(.white)
                    .contentShape(Capsule())
            }
            .padding(.horizontal)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isRecording {
                            startRecording()
                        }
                        dragOffset = value.translation
                        // Apple-style slide to cancel: if user slides horizontally beyond a threshold, mark willCancel
                        let cancelThreshold: CGFloat = 80
                        willCancel = abs(dragOffset.width) > cancelThreshold
                    }
                    .onEnded { _ in
                        if isRecording {
                            if willCancel {
                                // Cancel: stop and clear partial text
                                analyzer.stop()
                                latestText = ""
                                isFinal = false
                            } else {
                                // Normal stop
                                stopRecording()
                            }
                        }
                        // reset drag state
                        dragOffset = .zero
                        willCancel = false
                    }
            )
            .offset(x: isRecording ? dragOffset.width * 0.15 : 0)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Press and hold to start recording. Slide left or right to cancel. Release to stop.")

            Spacer()
        }
        .padding()
        .onAppear {
            analyzer.onTranscription = { text, final in
                latestText = text
                isFinal = final
            }
        }
    }

    private func startRecording() {
        isRecording = true
        Task {
            do {
                try await analyzer.captureAudio()
            } catch {
                isRecording = false
                latestText = "Error: \(error.localizedDescription)"
                isFinal = true
            }
        }
    }

    private func stopRecording() {
        analyzer.stop()
        isRecording = false
    }
}

#Preview {
    AudioRecordingView()
}
