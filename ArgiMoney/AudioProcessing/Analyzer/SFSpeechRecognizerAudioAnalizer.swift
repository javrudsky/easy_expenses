//
//  SpeeAnalizer.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 21/09/2026.
//
//import Foundation
//import AVFoundation
//import Speech
//
//
///// A simple audio-to-text analyzer that records microphone input and prints
///// recognized speech to the console using `SFSpeechRecognizer`.
/////
///// Usage:
/////   let analyzer = AudioAnalyzer()
/////   try await analyzer.captureAudio() // requests permissions and starts
/////   // or use analyzer.start() / analyzer.stop()
//final class SFSpeechRecognizerAudioAnalyzer: AudioTranscriber {
//    private let audioEngine = AVAudioEngine()
//    private let speechRecognizer: SFSpeechRecognizer?
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//
//    init() {
//        // Use the device's current locale by default
//        self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
//    }
//
//    /// Starts recording and streaming audio to the speech recognizer.
//    func start() async throws -> AsyncStream<AudioTranscriberResult> {
//        try await requestPermissions()
//        guard recognitionTask == nil else {
//            throw NSError(domain: "AudioAnalyzer", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Recognition already running"])
//        }
//        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
//            throw NSError(domain: "AudioAnalyzer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
//        }
//
//        // Configure audio session
//        let audioSession = AVAudioSession.sharedInstance()
//        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
//        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//
//
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        recognitionRequest?.shouldReportPartialResults = true
//
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.removeTap(onBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
//            if let self = self {
//                self.recognitionRequest?.append(buffer)
//            }
//        }
//
//        audioEngine.prepare()
//        try audioEngine.start()
//        guard let recognitionRequest = self.recognitionRequest else {
//            throw AudioError.unexpected("Recognition request couldn't be created")
//        }
//
//        let stream = AsyncStream<AudioTranscriberResult> { continuation in
//            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
//                if let result {
//                    let value = AudioTranscriberResult(text: result.bestTranscription.formattedString, isFinal: result.isFinal)
//                    continuation.yield(value)
//                }
//
//                if result?.isFinal == true {
//                    continuation.finish()
//                }
//
//                if error != nil {
//                    continuation.finish()
//                }
//
//                if (result?.isFinal == true) || (error != nil) {
//                    await self?.stop()
//                }
//            }
//        }
//
//        return stream
//    }
//
//    /// Stops recording and recognition.
//    func stop() async {
//        audioEngine.inputNode.removeTap(onBus: 0)
//        audioEngine.stop()
//        recognitionRequest?.endAudio()
//
//        recognitionTask?.cancel()
//        recognitionTask = nil
//        recognitionRequest = nil
//
//        // Try to deactivate audio session, ignore errors
//        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//    }
//
//
//    // MARK: -- Private Functions
//        /// Requests both speech and microphone permissions if needed.
//    private func requestPermissions() async throws {
//        // Request Speech recognition authorization
//        let speechAuth = SFSpeechRecognizer.authorizationStatus()
//        if speechAuth != .authorized {
//            let newStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
//                SFSpeechRecognizer.requestAuthorization { status in
//                    continuation.resume(returning: status)
//                }
//            }
//            guard newStatus == .authorized else {
//                throw AppAuthError.speechRecognitionNotGranted
//            }
//        }
//
//        // Request Microphone permission
//        let micStatus = await AVAudioApplication.requestRecordPermission()
//        guard micStatus else {
//            throw AppAuthError.audioRecordingNotGranted
//        }
//        
//    }
//}
//
