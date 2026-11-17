import Foundation

#if !PREMIUM || DEBUG

/// Community and preview implementation. Never grants premium access by default.
actor MockPurchaseService: PurchaseService {
    private var owned: Set<PurchaseProduct>
    private var continuation: AsyncStream<PurchaseEvent>.Continuation?
    var permitsPurchases: Bool

    init(owned: Set<PurchaseProduct> = [], permitsPurchases: Bool = false) {
        self.owned = owned
        self.permitsPurchases = permitsPurchases
    }

    func loadProducts() async throws -> [StoreProduct] {
        PurchaseProduct.allCases.map {
            StoreProduct(product: $0,
                         title: $0.fallbackTitle,
                         detail: "One-time unlock",
                         symbolName: $0.symbolName,
                         displayPrice: "Preview")
        }
    }

    func purchase(_ product: PurchaseProduct) async throws -> PurchaseOutcome {
        guard permitsPurchases else { throw PurchaseError.notAllowed }
        owned.insert(product)
        continuation?.yield(.entitlementsChanged)
        return .success
    }

    func currentPurchases() async throws -> Set<PurchaseProduct> { owned }
    func restorePurchases() async throws { continuation?.yield(.entitlementsChanged) }

    func events() async -> AsyncStream<PurchaseEvent> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation() }
            }
        }
    }

    private func removeContinuation() { continuation = nil }

    /// For unit tests and previews only.
    func setOwned(_ products: Set<PurchaseProduct>) {
        owned = products
        continuation?.yield(.entitlementsChanged)
    }
}

extension PurchaseProduct {
    var fallbackTitle: String {
        switch self {
        case .cashFlow: "Cash Flow Analysis"
        case .spending: "Spending Trends"
        case .accountsReport: "Account Analysis"
//        case .insights: "Smart Insights"
        case .accountModule: "Accounts & Transfers"
        case .categoryModule: "Custom Categories"
//        case .themes: "Themes"
        case .advancedImport: "Advanced Data Transfer"
        case .premiumBundle: "Argi Premium Bundle"
        }
    }

    var symbolName: String {
        switch self {
        case .cashFlow: "arrow.left.arrow.right"
        case .spending: "chart.bar.xaxis"
        case .accountsReport: "chart.pie"
//        case .insights: "sparkles"
        case .accountModule: "wallet.pass"
        case .categoryModule: "square.grid.2x2"
//        case .themes: "paintpalette"
        case .advancedImport: "square.and.arrow.down"
        case .premiumBundle: "crown"
        }
    }
}

#endif
