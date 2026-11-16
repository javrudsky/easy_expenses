import Foundation

enum PremiumFeature: String, CaseIterable, Hashable, Sendable, Identifiable {
    case cashFlowReport, spendingTrendsReport, accountAnalysisReport, smartInsightsReport
    case accountCustomization, accountTransfers, categoryManagement, themes, advancedImport
    var id: String { rawValue }
}

/// Replace example IDs with identifiers configured in App Store Connect before release.
enum PurchaseProduct: String, CaseIterable, Hashable, Sendable, Identifiable {
    case cashFlow = "com.argimoney.report.cashflow"
    case spending = "com.argimoney.report.spendingtrends"
    case accountsReport = "com.argimoney.report.accountanalysis"
    case insights = "com.argimoney.report.smartinsights"
    case accountModule = "com.argimoney.module.accounts"
    case categoryModule = "com.argimoney.module.categories"
    case themes = "com.argimoney.themes"
    case advancedImport = "com.argimoney.import.advanced"
    case premiumBundle = "com.argimoney.premium.all"
    var id: String { rawValue }
}

struct StoreProduct: Identifiable, Hashable, Sendable {
    let product: PurchaseProduct
    let title: String
    let detail: String
    let displayPrice: String
    let symbolName: String
    var id: String { product.rawValue }
    init(product: PurchaseProduct,
         title: String,
         detail: String,
         symbolName: String,
         displayPrice: String) {
        self.product = product
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.displayPrice = displayPrice
    }
}

enum PurchaseOutcome: Sendable, Equatable {
    case success, pending, cancelled
}

enum PurchaseError: Error, LocalizedError, Sendable {
    case unavailable, unverified, missingProduct, notAllowed
    var errorDescription: String? {
        switch self {
        case .unavailable: "Purchases are unavailable right now. Please try again later."
        case .unverified: "The App Store could not verify this purchase."
        case .missingProduct: "This product is not currently available."
        case .notAllowed: "This purchase is not available in this build."
        }
    }
}
