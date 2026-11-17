import Foundation
import SwiftUI

struct PremiumProductRow: View {
    let product: PurchaseProduct
    let metadata: StoreProduct?
    let owned: Bool
    let isBusy: Bool
    let action: () -> Void

    init(product: PurchaseProduct,
         metadata: StoreProduct?,
         owned: Bool,
         isBusy: Bool,
         action: @escaping () -> Void) {
        self.product = product
        self.metadata = metadata
        self.owned = owned
        self.isBusy = isBusy
        self.action = action
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(metadata?.symbolName ?? "")
                .resizable()
                .frame(width: 60, height: 60)
                .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(metadata?.title ?? product.localizedTitle).font(.headline)
                Text(metadata?.detail ?? String(localized: "One-time unlock"))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 4)
            if owned {
                    Label("Owned", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
            } else {
                Button(action: action) {
                    if isBusy { ProgressView() }
                    else { Text(metadata?.displayPrice ?? String(localized: "Unavailable")) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBusy || metadata == nil)
                    .accessibilityLabel(Text("Buy \(product.localizedTitle)"))
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PremiumStoreView: View {
    @Environment(FeatureAccessManager.self) private var access
    @State private var showingRestoreResult = false

    init() {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Argi Premium", systemImage: "crown.fill")
                        .font(.largeTitle.bold()).foregroundStyle(.primary)
                    Text("Unlock the features you need. Pay once, no subscription.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)

                if access.state == .loading {
                    ProgressView("Checking purchases…")
                } else if case .failed = access.state {
                    Label("Unable to refresh purchases. Showing last known status.",
                          systemImage: "wifi.exclamationmark")
                        .font(.caption).foregroundStyle(.orange)
                    Button("Retry") { Task { await access.refreshEntitlements() } }
                }

                if access.metadata(for: .premiumBundle) != nil {
                    productRow(.premiumBundle)
                }
                Text("Individual upgrades").font(.title3.bold())
                ForEach(PurchaseProduct.allCases.filter { $0 != .premiumBundle }) { product in
                    productRow(product)
                }
                Button("Restore Purchases") {
                    Task { await access.restore(); showingRestoreResult = true }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                Text("Purchases are linked to your App Store account. Previous individual purchases are not automatically credited toward the complete bundle.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Premium")
        .alert("Purchase information", isPresented: Binding(
            get: { access.lastError != nil || showingRestoreResult },
            set: { if !$0 { access.clearError(); showingRestoreResult = false } }
        )) {
            Button("OK") { access.clearError(); showingRestoreResult = false }
        } message: {
            Text(access.lastError ?? String(localized: "Your purchases have been checked."))
        }
    }

    private func productRow(_ product: PurchaseProduct) -> some View {
        PremiumProductRow(product: product, metadata: access.metadata(for: product),
                          owned: access.owns(product) || (product != .premiumBundle && access.owns(.premiumBundle)),
                          isBusy: access.busyProduct != nil) {
            Task { _ = await access.purchase(product) }
        }
    }
}

struct PremiumFeaturePreview<Preview: View>: View {
    @Environment(FeatureAccessManager.self) private var access
    let feature: PremiumFeature
    let title: String
    let summary: String
    @ViewBuilder let preview: () -> Preview

    init(feature: PremiumFeature, title: String, summary: String,
                @ViewBuilder preview: @escaping () -> Preview) {
        self.feature = feature; self.title = title; self.summary = summary
        self.preview = preview
    }

    var body: some View {
        let product = ProductCatalog.product(for: feature)
        ScrollView {
            VStack(spacing: 18) {
                preview().allowsHitTesting(false).accessibilityHidden(true)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topTrailing) {
                        Label("Preview", systemImage: "lock.fill")
                            .font(.caption.bold()).padding(8)
                            .background(.regularMaterial, in: Capsule())
                    }
                Text(LocalizedStringKey(title)).font(.title2.bold())
                Text(LocalizedStringKey(summary)).multilineTextAlignment(.center).foregroundStyle(.secondary)
                if access.isUnlocked(feature) {
                    Label("Unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        Task { _ = await access.purchase(product) }
                    } label: {
                        if access.busyProduct == product { ProgressView() }
                        else {
                            Text(access.metadata(for: product).map { String(localized: "Unlock for \($0.displayPrice)") }
                                 ?? String(localized: "Currently unavailable"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(access.busyProduct != nil || access.metadata(for: product) == nil)
                }
            }
            .padding()
        }
            .navigationTitle(LocalizedStringKey(title))
    }
}

/// Wraps the actual feature rather than duplicating access logic in each view.
struct PremiumGate<Unlocked: View, Locked: View>: View {
    @Environment(FeatureAccessManager.self) private var access
    let feature: PremiumFeature
    @ViewBuilder let unlocked: () -> Unlocked
    @ViewBuilder let locked: () -> Locked
    init(feature: PremiumFeature, @ViewBuilder unlocked: @escaping () -> Unlocked,
                @ViewBuilder locked: @escaping () -> Locked) {
        self.feature = feature; self.unlocked = unlocked; self.locked = locked
    }
    var body: some View {
        Group {
            if access.state == .loading { ProgressView("Checking purchases…") }
            else if access.isUnlocked(feature) { unlocked() }
            else { locked() }
        }
    }
}
