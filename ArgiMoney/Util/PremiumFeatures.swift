import Foundation

/// Central place to decide whether premium-only features are available.
///
/// The app currently ships as two targets. The premium target defines the
/// `PREMIUM` compilation condition, while the community target does not.
/// Keeping the check here makes it easy to replace with a StoreKit entitlement
/// check later without touching every feature.
enum PremiumFeatures {
    static var isEnabled: Bool {
        #if PREMIUM
        return true
        #else
        return false
        #endif
    }
}
