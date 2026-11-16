import Foundation

/// Events are hints to refresh ownership, never evidence of ownership themselves.
enum PurchaseEvent: Sendable { case entitlementsChanged }

protocol PurchaseService: Sendable {
    func loadProducts() async throws -> [StoreProduct]
    func purchase(_ product: PurchaseProduct) async throws -> PurchaseOutcome
    func currentPurchases() async throws -> Set<PurchaseProduct>
    func restorePurchases() async throws
    /// Must be started early and remain active for the application's lifetime.
    func events() async -> AsyncStream<PurchaseEvent>
}
