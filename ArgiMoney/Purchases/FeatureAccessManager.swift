import Foundation
import Observation

@MainActor @Observable
final class FeatureAccessManager {
    enum OwnershipState: Equatable { case loading, ready, failed(String) }

    private(set) var state: OwnershipState = .loading
    private(set) var purchasedProducts: Set<PurchaseProduct> = []
    private(set) var products: [StoreProduct] = []
    private(set) var busyProduct: PurchaseProduct?
    private(set) var lastError: String?

    @ObservationIgnored private let service: any PurchaseService
    @ObservationIgnored private var listener: Task<Void, Never>?
    @ObservationIgnored private var started = false

    init(service: any PurchaseService) { self.service = service }

    var unlockedFeatures: Set<PremiumFeature> {
        ProductCatalog.unlockedFeatures(for: purchasedProducts)
    }

    func isUnlocked(_ feature: PremiumFeature) -> Bool {
        unlockedFeatures.contains(feature)
    }

    func owns(_ product: PurchaseProduct) -> Bool { purchasedProducts.contains(product) }
    func metadata(for product: PurchaseProduct) -> StoreProduct? {
        products.first { $0.product == product }
    }

    /// Call once at app startup. Safe to call repeatedly.
    func start() async {
        guard !started else { return }
        started = true
        // Register the stream before the first entitlement refresh.
        listener = Task { [weak self, service] in
            let stream = await service.events()
            for await _ in stream {
                guard !Task.isCancelled else { break }
                await self?.refreshEntitlements()
            }
        }
        await refreshEntitlements()
        do {
            products = try await service.loadProducts()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        do {
            purchasedProducts = try await service.currentPurchases()
            state = .ready
        } catch {
            // Preserve last known ownership for transient errors, but mark as stale.
            state = .failed(error.localizedDescription)
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    func purchase(_ product: PurchaseProduct) async -> PurchaseOutcome? {
        guard busyProduct == nil else { return nil }
        busyProduct = product
        lastError = nil
        defer { busyProduct = nil }
        do {
            let outcome = try await service.purchase(product)
            if outcome == .success { await refreshEntitlements() }
            return outcome
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func restore() async {
        lastError = nil
        do {
            try await service.restorePurchases()
            await refreshEntitlements()
        } catch { lastError = error.localizedDescription }
    }

    func clearError() { lastError = nil }
    func stop() { listener?.cancel(); listener = nil; started = false }
}
