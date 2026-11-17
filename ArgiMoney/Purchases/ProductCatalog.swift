import Foundation

enum ProductCatalog {
    static let entitlements: [PurchaseProduct: Set<PremiumFeature>] = [
        .cashFlow: [.cashFlowReport],
        .spending: [.spendingTrendsReport],
        .accountsReport: [.accountAnalysisReport],
//        .insights: [.smartInsightsReport],
        .accountModule: [.accountCustomization, .accountTransfers],
        .categoryModule: [.categoryManagement],
//        .themes: [.themes],
        .advancedImport: [.advancedImport],
        .premiumBundle: Set(PremiumFeature.allCases)
    ]

    static func unlockedFeatures(for products: Set<PurchaseProduct>) -> Set<PremiumFeature> {
        products.reduce(into: Set<PremiumFeature>()) { result, product in
            result.formUnion(entitlements[product] ?? [])
        }
    }

    static func product(for feature: PremiumFeature) -> PurchaseProduct {
        switch feature {
        case .cashFlowReport: .cashFlow
        case .spendingTrendsReport: .spending
        case .accountAnalysisReport: .accountsReport
//        case .smartInsightsReport: .insights
        case .accountCustomization, .accountTransfers: .accountModule
        case .categoryManagement: .categoryModule
//        case .themes: .themes
        case .advancedImport: .advancedImport
        }
    }
}
