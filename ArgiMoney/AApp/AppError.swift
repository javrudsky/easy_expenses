//
//  AppError.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 14/09/2026.
//

import Foundation

enum ViewError: Error {
    case couldNotCreateView
}

enum CommonError: Error {
    case unexpected(String)
}

enum ParserError: Error {
    case onParsing(String)
}

enum TransactionError: Error {
   case onSave(String)
}

enum AudioError: Error {
    case alreadyRunning
    case unavailableTargetFormat
    case bufferCopyError
    case unexpected(String)
}

enum AppAuthError: Error {
    case speechRecognitionNotGranted
    case audioRecordingNotGranted
}

enum DataTransferError: Error {
    case wrongFile(String)
    case permissionDenied(String)
    case wrongCsvFormat(String)
    case invalidData(String)
}
