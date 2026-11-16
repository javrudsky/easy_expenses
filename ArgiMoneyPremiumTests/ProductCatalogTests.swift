import XCTest
@testable import ArgiMoneyPremium

final class ProductCatalogTests: XCTestCase {
    func testAccountModuleUnlocksBothFeatures() {
        let features = ProductCatalog.unlockedFeatures(for: [.accountModule])
        XCTAssertTrue(features.contains(.accountCustomization))
        XCTAssertTrue(features.contains(.accountTransfers))
        XCTAssertFalse(features.contains(.themes))
    }

    func testBundleUnlocksEveryFeature() {
        XCTAssertEqual(ProductCatalog.unlockedFeatures(for: [.premiumBundle]),
                       Set(PremiumFeature.allCases))
    }

    func testEachFeatureHasAnIndividualProduct() {
        for feature in PremiumFeature.allCases {
            XCTAssertTrue(ProductCatalog.entitlements[ProductCatalog.product(for: feature)]?.contains(feature) == true)
        }
    }

    @MainActor
    func testMockStartsLockedAndUnlocksWhenPurchased() async {
        let service = MockPurchaseService(permitsPurchases: true)
        let manager = FeatureAccessManager(service: service)
        await manager.start()
        XCTAssertFalse(manager.isUnlocked(.cashFlowReport))
        let result = await manager.purchase(.cashFlow)
        XCTAssertEqual(result, .success)
        XCTAssertTrue(manager.isUnlocked(.cashFlowReport))
        manager.stop()
    }
}
