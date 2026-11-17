//
//  AppError.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 14/09/2026.
//

import Foundation

enum ViewError: Error, LocalizedError {
    case couldNotCreateView

    var errorDescription: String? {
        String(localized: "Could not create the requested screen.")
    }
}

enum CommonError: Error, LocalizedError {
    case unexpected(String)

    var errorDescription: String? {
        if case .unexpected(let message) = self { return message }
        return nil
    }
}

enum ParserError: Error, LocalizedError {
    case onParsing(String)

    var errorDescription: String? {
        switch self {
        case .onParsing(let message): return message
        }
    }
}

enum TransactionError: Error, LocalizedError {
   case onSave(String)

    var errorDescription: String? {
        if case .onSave(let message) = self { return message }
        return nil
    }
}

enum AudioError: Error, LocalizedError {
    case alreadyRunning
    case unavailableTargetFormat
    case bufferCopyError
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case .alreadyRunning: String(localized: "Audio recording is already running.")
        case .unavailableTargetFormat: String(localized: "The requested audio format is unavailable.")
        case .bufferCopyError: String(localized: "Could not process the audio buffer.")
        case .unexpected(let message): message
        }
    }
}

enum AppAuthError: Error, LocalizedError {
    case speechRecognitionNotGranted
    case audioRecordingNotGranted

    var errorDescription: String? {
        switch self {
        case .speechRecognitionNotGranted: String(localized: "Speech recognition permission is required.")
        case .audioRecordingNotGranted: String(localized: "Microphone permission is required.")
        }
    }
}

enum DataTransferError: Error, LocalizedError {
    case wrongFile(String)
    case permissionDenied(String)
    case wrongCsvFormat(String)
    case invalidData(String)
    case importFail(String)

    var errorDescription: String? {
        switch self {
        case .wrongFile(let message), .permissionDenied(let message),
             .wrongCsvFormat(let message), .invalidData(let message),
             .importFail(let message): message
        }
    }
}
