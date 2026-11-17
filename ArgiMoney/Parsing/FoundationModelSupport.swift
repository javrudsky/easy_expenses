//
//  FoundationModelSupport.swift
//  ArgiMoney
//
//  Shared access to the on-device Apple Foundation Model.
//

import Foundation
import FoundationModels

/// Availability of the on-device system model, including whether the system can
/// still download/prepare the model or the device will never be able to run it.
enum FoundationModelAvailability: Equatable, Sendable {
    case available
    case unavailable(UnavailabilityReason)

    enum UnavailabilityReason: String, CaseIterable, Equatable, Sendable {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
    }

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var unavailableReason: UnavailabilityReason? {
        if case .unavailable(let reason) = self { return reason }
        return nil
    }
}

extension FoundationModelAvailability.UnavailabilityReason {
    var title: String {
        switch self {
        case .deviceNotEligible:
            return "Device not supported"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is turned off"
        case .modelNotReady:
            return "On-device model not ready"
        }
    }

    var message: String {
        switch self {
        case .deviceNotEligible:
            return "This device doesn't support Apple Intelligence, so the on-device model can't run here."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to let the on-device model run on this device."
        case .modelNotReady:
            return "The system is downloading or preparing the on-device model. Try again in a few minutes."
        }
    }

    /// Explains whether the model can still be downloaded/prepared by the system.
    var downloadExplanation: String {
        switch self {
        case .deviceNotEligible:
            return "The model cannot be downloaded because this device doesn't support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "The model can be downloaded by the system after Apple Intelligence is enabled."
        case .modelNotReady:
            return "The model is being downloaded or prepared by the system. No download is needed from this app."
        }
    }

    var canBeDownloaded: Bool {
        switch self {
        case .deviceNotEligible:
            return false
        case .appleIntelligenceNotEnabled, .modelNotReady:
            return true
        }
    }

    var needsSettingsAction: Bool {
        self == .appleIntelligenceNotEnabled
    }
}

/// Languages the app currently phrases its model instructions for.
enum FoundationModelLanguage: String, Equatable, Sendable {
    case english
    case spanish

    static func preferred(for locale: Locale) -> FoundationModelLanguage {
        let code = locale.language.languageCode?.identifier ?? locale.identifier
        return code.lowercased().hasPrefix("es") ? .spanish : .english
    }

    var instruction: String {
        switch self {
        case .english:
            return "You MUST respond in English."
        case .spanish:
            return "You MUST respond in Spanish. Responde siempre en español, usando un español neutro y claro."
        }
    }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        }
    }
}

/// Small wrapper around `SystemLanguageModel` that centralizes availability,
/// locale/language checks and session creation.
struct FoundationModelSupport: Sendable {
    private static let spanishFallbackLocale = Locale(identifier: "es-419")

    let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    var availability: FoundationModelAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable(.deviceNotEligible)
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(.appleIntelligenceNotEnabled)
        case .unavailable(.modelNotReady):
            return .unavailable(.modelNotReady)
        default:
            // Treat unexpected reasons as "not ready yet" so the UI can offer a retry.
            return .unavailable(.modelNotReady)
        }
    }

    /// Uses the framework API that accounts for language fallbacks (for example
    /// `es-AR` being covered by the supported `es-419` language).
    var currentLocaleIsSupported: Bool {
        model.supportsLocale(.current)
    }

    /// Locale used to steer generation. When the device locale isn't supported we
    /// try a supported Spanish locale for Spanish users and fall back to English
    /// otherwise.
    var generationLocale: Locale {
        if currentLocaleIsSupported { return .current }
        if FoundationModelLanguage.preferred(for: .current) == .spanish,
           model.supportsLocale(Self.spanishFallbackLocale) {
            return Self.spanishFallbackLocale
        }
        return Locale(identifier: "en-US")
    }

    var responseLanguage: FoundationModelLanguage {
        FoundationModelLanguage.preferred(for: generationLocale)
    }

    var usesFallbackLanguage: Bool {
        !currentLocaleIsSupported
    }

    var fallbackLanguageNotice: String? {
        guard usesFallbackLanguage else { return nil }
        return "Your device language isn't supported by the on-device model, so insights are generated in \(responseLanguage.displayName)."
    }

    var localeInstruction: String {
        "The person's locale is \(generationLocale.identifier)."
    }

    var languageInstruction: String {
        "\(localeInstruction) \(responseLanguage.instruction)"
    }

    func makeSession(instructions: String) -> LanguageModelSession {
        LanguageModelSession(model: model, instructions: instructions)
    }
}

/// Converts Foundation Models errors into messages suitable for an alert or a
/// failure card.
enum FoundationModelErrorDescription {
    /// Returns an availability reason when the error means the model itself is
    /// not ready, so the UI can show the same download guidance as a pre-flight check.
    static func availabilityReason(for error: Error) -> FoundationModelAvailability.UnavailabilityReason? {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            
            if let systemError = error as? SystemLanguageModel.Error,
               case .assetsUnavailable = systemError {
                return .modelNotReady
            }
        }
        #endif
        if let generationError = error as? LanguageModelSession.GenerationError,
           case .assetsUnavailable = generationError {
            return .modelNotReady
        }
        return nil
    }

    static func message(for error: Error) -> String {
#if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            if let systemError = error as? SystemLanguageModel.Error {
                switch systemError {
                case .assetsUnavailable(_):
                    return FoundationModelAvailability.UnavailabilityReason.modelNotReady.message
                @unknown default:
                    return systemError.localizedDescription
                }
            }
        }
#endif

        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .unsupportedLanguageOrLocale(_):
                return "The on-device model doesn't support the current language. Try a supported language."
            case .assetsUnavailable(_):
                return FoundationModelAvailability.UnavailabilityReason.modelNotReady.message
            case .exceededContextWindowSize(_):
                return "The selected period contains too much data for the on-device model. Try a shorter period."
            case .rateLimited(_), .concurrentRequests(_):
                return "The on-device model is busy. Wait a moment and try again."
            case .guardrailViolation(_), .refusal(_, _):
                return "The on-device model couldn't generate a response for this content."
            case .decodingFailure(_):
                return "The on-device model returned an unexpected response. Try again."
            case .unsupportedGuide(_):
                return "The requested response format isn't supported by the on-device model."
            @unknown default:
                return generationError.localizedDescription
            }
        }

        return error.localizedDescription
    }
}
