import Foundation
import StoreKit
typealias SKTransaction = StoreKit.Transaction

actor StoreKitPurchaseService: PurchaseService {
    private var storeProducts: [PurchaseProduct: Product] = [:]
    private var continuation: AsyncStream<PurchaseEvent>.Continuation?
    private var transactionTask: Task<Void, Never>?
    private var unfinishedTask: Task<Void, Never>?

    init() {
        // Transaction observation starts when events() is called at app startup.
    }

    func events() async -> AsyncStream<PurchaseEvent> {
        let stream = AsyncStream<PurchaseEvent>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.stopListening() }
            }
        }
        startListening()
        return stream
    }

    private func startListening() {
        guard transactionTask == nil else { return }
        transactionTask = Task { [weak self] in
            for await result in SKTransaction.updates {
                guard !Task.isCancelled else { break }
                await self?.process(result)
            }
        }
        unfinishedTask = Task { [weak self] in
            for await result in SKTransaction.unfinished {
                guard !Task.isCancelled else { break }
                await self?.process(result)
            }
        }
    }

    private func process(_ result: VerificationResult<SKTransaction>) async {
        guard case .verified(let transaction) = result else { return }
        // Refresh before finish so a listener can observe the new ownership.
        continuation?.yield(.entitlementsChanged)
        await transaction.finish()
    }

    private func stopListening() {
        transactionTask?.cancel(); unfinishedTask?.cancel()
        transactionTask = nil; unfinishedTask = nil; continuation = nil
    }

    func loadProducts() async throws -> [StoreProduct] {
        let found = try await Product.products(for: PurchaseProduct.allCases.map(\.rawValue))
        var result: [StoreProduct] = []
        for item in found {
            guard let id = PurchaseProduct(rawValue: item.id) else { continue }
            storeProducts[id] = item
            result.append(StoreProduct(product: id,
                                       title: item.displayName,
                                       detail: item.description,
                                       symbolName: "thumbnail_\(item.id)",
                                       displayPrice: item.displayPrice))
        }
        return result.sorted { $0.title < $1.title }
    }

    func purchase(_ product: PurchaseProduct) async throws -> PurchaseOutcome {
        if storeProducts[product] == nil { _ = try await loadProducts() }
        guard let item = storeProducts[product] else { throw PurchaseError.missingProduct }
        let result = try await item.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw PurchaseError.unverified }
            continuation?.yield(.entitlementsChanged)
            await transaction.finish()
            return .success
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: throw PurchaseError.unavailable
        }
    }

    func currentPurchases() async throws -> Set<PurchaseProduct> {
        var owned: Set<PurchaseProduct> = []
//        for await result in SKTransaction.currentEntitlements {
        for await result in SKTransaction.all {
            print(result)
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  let id = PurchaseProduct(rawValue: transaction.productID) else { continue }
            owned.insert(id)
        }
        return owned
    }

    func restorePurchases() async throws {
        // Only call following an explicit Restore Purchases user action.
        try await AppStore.sync()
    }
}
