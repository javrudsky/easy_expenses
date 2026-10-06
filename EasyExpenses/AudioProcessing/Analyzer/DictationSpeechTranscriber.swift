import Speech
import AVFoundation

final class DictationSpeechTranscriber: AudioTranscriber {
    
    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    
    private enum State { case idle, running, stopping }
    private var state: State = .idle
    
    func start() async throws -> AsyncStream<AudioTranscriberResult>? {
        guard state == .idle else { throw AudioError.alreadyRunning }   // add this case
        state = .running
        
        do {
            if try await requestPermissions() {
                state = .idle
                return nil
            }
            
            guard let locale = await DictationTranscriber.supportedLocale(equivalentTo: Locale.current) else {
                throw AudioError.unavailableTargetFormat
            }
            let transcriber = DictationTranscriber(locale: locale, preset: .shortDictation)
            
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }
            guard let targetFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                throw AudioError.unavailableTargetFormat
            }
            
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            let (audioSequence, audioContinuation) = AsyncStream<AnalyzerInput>.makeStream()
            let (resultStream, resultCont) = AsyncStream<AudioTranscriberResult>.makeStream()
            
            self.analyzer = analyzer
            self.inputContinuation = audioContinuation
            
            // Consume results BEFORE starting the analyzer; finish the outgoing stream however this ends.
            resultsTask = Task {
                defer { resultCont.finish() }
                do {
                    for try await result in transcriber.results {
                        resultCont.yield(AudioTranscriberResult(text: result.text, isFinal: result.isFinal))
                    }
                } catch {
                    print("Results error: \(error)")
                }
            }
            
            try await analyzer.start(inputSequence: audioSequence)   // errors surface to the caller
            
            let input = audioEngine.inputNode
            input.installTap(onBus: 0,
                             bufferSize: 4096,
                             format: input.outputFormat(forBus: 0),
                             block: Self.makeTapBlock(targetFormat: targetFormat,
                                                      continuation: audioContinuation))
            audioEngine.prepare()
            try audioEngine.start()
            return resultStream
        } catch {
            await stop()
            throw error
        }
        
    }
    
    func stop() async {
        guard state == .running else { return }   // ignores repeated calls and calls mid-stop
        state = .stopping
        
        // Take ownership of the resources and clear the properties right now,
        // so nothing after an await can clobber a later session.
        let analyzer = self.analyzer
        let resultsTask = self.resultsTask
        let continuation = self.inputContinuation
        self.analyzer = nil
        self.resultsTask = nil
        self.inputContinuation = nil
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        continuation?.finish()
        
        do {
            try await analyzer?.finalizeAndFinishThroughEndOfInput()
        } catch {
            print("Finalize error: \(error)")
            await analyzer?.cancelAndFinishNow()
        }
        await resultsTask?.value
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = .idle             // only now can a new start() begin
    }

      // MARK: - Audio thread

    /// nonisolated on purpose: the block runs on a realtime audio thread, not the main actor.
    private nonisolated static func makeTapBlock(
        targetFormat: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation
    ) -> AVAudioNodeTapBlock {
        let converter = BufferConverter()      // owned by the tap only, no sharing
        return { buffer, _ in
            do {
                let converted = try converter.convert(buffer, to: targetFormat)
                continuation.yield(AnalyzerInput(buffer: converted))
            } catch {
                print("Resample error: \(error)")
            }
        }
    }

    // requestPermissions() unchanged
}

private final class BufferConverter {
    private var converter: AVAudioConverter?

    private final class OneShot: @unchecked Sendable {
        let buffer: AVAudioPCMBuffer
        var consumed = false
        init(_ buffer: AVAudioPCMBuffer) { self.buffer = buffer }
    }

    func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        if buffer.format == format { return buffer }

        if converter == nil || converter?.inputFormat != buffer.format || converter?.outputFormat != format {
            converter = AVAudioConverter(from: buffer.format, to: format)
        }
        guard let converter else { throw AudioError.unavailableTargetFormat }

        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw AudioError.unavailableTargetFormat
        }

        let source = OneShot(buffer)
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, outStatus in
            if source.consumed {
                outStatus.pointee = .noDataNow   // don't hand the same buffer back twice
                return nil
            }
            source.consumed = true
            outStatus.pointee = .haveData
            return source.buffer
        }
        if status == .error { throw error ?? AudioError.unavailableTargetFormat }
        return output
    }
}







/////////////////////////////////////
//class DictationSpeechTranscriber: AudioTranscriber {
//    
//    
//    private let audioEngine = AVAudioEngine()
//    private var analyzer: SpeechAnalyzer?
//    private var transcriber: DictationTranscriber?
//    
//    private var inputSequence: AsyncStream<AnalyzerInput>?
//    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
//    private var audioConverter: AVAudioConverter?
//    
//    func start() async throws -> AsyncStream<AudioTranscriberResult> {
//        
//        try await requestPermissions()
//        let audioSession = AVAudioSession.sharedInstance()
//        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
//        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        
//        
//        guard let allocatedLocale = await DictationTranscriber.supportedLocale(equivalentTo: Locale.current) else {
//            print("This locale is completely unsupported by the Dictation hardware profile.")
//            throw AudioError.unavailableTargetFormat
//        }
//        let transcriber = DictationTranscriber(locale: allocatedLocale, preset: .shortDictation)
//        guard let targetFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
//            throw AudioError.unavailableTargetFormat
//        }
//        
//        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
//            try await installationRequest.downloadAndInstall()
//        }
//        
//        let analyzer = SpeechAnalyzer(modules: [transcriber])
//        let inputNode = audioEngine.inputNode
//        let nativeHardwareFormat = inputNode.outputFormat(forBus: 0)
//
//        self.transcriber = transcriber
//        self.analyzer = analyzer
//        
//        let (audioSequence, audioContinuation) = AsyncStream<AnalyzerInput>.makeStream()
//        self.inputSequence = audioSequence
//        self.inputContinuation = audioContinuation
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeHardwareFormat) { [weak self] buffer, _ in
//            guard let self = self else { return }
//            
//            if let convertedBuffer = try? self.resample(pcmBuffer: buffer, to: targetFormat) {
//                self.inputContinuation?.yield(AnalyzerInput(buffer: convertedBuffer))
//            } else {
//                print("Error resampling")
//            }
//        }
//        
//        // Create a stream to return to callers
//        let (resultStream, resultCont) = AsyncStream<AudioTranscriberResult>.makeStream()
//        
//        // Forward results out
//        resultCont.onTermination = { reason in print("terminated cont result \(reason)")}
//        Task {
//            defer {
//                print("finish result called")
//                resultCont.finish()
//            }
//
//            do {
//                for try await result in transcriber.results {
//                    print("transcriber.results.loop")
//                    resultCont.yield(AudioTranscriberResult(text: result.text,
//                                                            isFinal: result.isFinal)) // forward to the returned stream
//                }
//            } catch {
//                print("Error on wait for results \(error)")
//            }
//        }
//        
//        Task {
//            do {
//                try await analyzer.start(inputSequence: audioSequence)
//            } catch {
//                print ("errr \(error)")
//            }
//        }
//        
//        audioEngine.prepare()
//        try audioEngine.start()
//
//        return resultStream
//    }
//    
//    
//    func stop() {
//        
//        audioEngine.inputNode.removeTap(onBus: 0)
//        audioEngine.stop()
//        
//        // Since this class is isolated to the main actor, call directly without spawning a new Task.
//        audioConverter = nil
//        // Try to deactivate audio session, ignore errors
//        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//        inputContinuation?.finish()
//        guard let lanalyzer = self.analyzer else {
//            return
//        }
////        guard let ic = self.inputContinuation else {
////            return
////        }
//        
//        Task {
//            do {
//                try await lanalyzer.finalize(through: nil)
////                ic.finish() // Forces final text flushing
//             //   rc.finish()
//                print("ana fin END")
//            } catch {
//                print("Finalize error ana")
//            }
//        }
//    }
//    
// MARK: -- Private
   
    /// Requests both speech and microphone permissions if needed.
    private func requestPermissions() async throws -> Bool {
        var shouldCancelRecord = false
        // 1) Speech recognition
        let speechAuth = SFSpeechRecognizer.authorizationStatus()
        if speechAuth != .authorized {
            let newStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                    shouldCancelRecord = true
                }
            }
            guard newStatus == .authorized else {
                throw AppAuthError.speechRecognitionNotGranted
            }
        }
        
        // 2) Microphone (record permission)
        let prevMicStatus = AVAudioApplication.shared.recordPermission
        if prevMicStatus == .denied || prevMicStatus == .undetermined {
            shouldCancelRecord = true
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            throw AppAuthError.audioRecordingNotGranted
        }
        return shouldCancelRecord
    }
//
//    // High-performance live format converter wrapper
//    private func resample(pcmBuffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
//        if pcmBuffer.format == targetFormat { return pcmBuffer }
//        
//        if audioConverter == nil || audioConverter?.outputFormat != targetFormat {
//            audioConverter = AVAudioConverter(from: pcmBuffer.format, to: targetFormat)
//        }
//        
//        guard let converter = audioConverter else {
//            print("error 1 conv")
//            throw AudioError.unavailableTargetFormat
//        }
//        
//        let sampleRateRatio = targetFormat.sampleRate / pcmBuffer.format.sampleRate
//        let capacity = AVAudioFrameCount(Double(pcmBuffer.frameLength) * sampleRateRatio) + 1
//        
//        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else {
//            print("Error converting 2")
//            throw AudioError.unavailableTargetFormat
//        }
//        
//        var error: NSError?
//        
//        // Avoid capturing non-Sendable pcmBuffer in a @Sendable closure by copying its data
//        guard let sendBuffer = try? AVAudioPCMBufferSendableWrapper(buffer: pcmBuffer) else {
//            print("Could not parse buffer")
//            throw AudioError.unavailableTargetFormat
//        }
//        
//        let inputBlock: AVAudioConverterInputBlock =
//        { (inNumPackets: AVAudioPacketCount,
//           outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? in
//            outStatus.pointee = .haveData
//            return sendBuffer.buffer
//        }
//
//        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
//
//        if error != nil {
//            print("Error converting buffer")
//            throw AudioError.unavailableTargetFormat
//        }
//        return outputBuffer
//    }
//    
//}
//
//// Wrapper to convert the PCM buffer in a sendable object
//// Copying the content to make sure that the memory remains untoched
//final class AVAudioPCMBufferSendableWrapper: @unchecked Sendable {
//    private(set) var buffer: AVAudioPCMBuffer
//    init(buffer: AVAudioPCMBuffer) throws {
//        self.buffer = buffer
//    }
//}
//
