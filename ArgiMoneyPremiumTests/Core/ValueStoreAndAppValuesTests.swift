import Foundation
import Testing
@testable import ArgiMoneyPremium

@Suite("Value store and app values tests")
struct ValueStoreAndAppValuesTests {
    private func makeStore() -> DefaultValueStore {
        DefaultValueStore(suiteName: "ValueStoreAndAppValuesTests.\(UUID().uuidString)")
    }

    @Test
    func valueStoreReadsDefaultsAndRoundTripsStoredValues() {
        let store = makeStore()

        #expect(store.getString(forKey: "missing", default: "fallback") == "fallback")
        #expect(store.getBool(forKey: "missing-bool", default: true))
        #expect(store.getArray(forKey: "missing-array", default: [1, 2]) == [1, 2])

        store.setString("value", forKey: "string")
        store.setBool(false, forKey: "bool")
        store.setArray(["one", "two"], forKey: "array")

        #expect(store.getString(forKey: "string", default: nil) == "value")
        #expect(!store.getBool(forKey: "bool", default: true))
        #expect(store.getArray(forKey: "array", default: []) == ["one", "two"])

        store.setString(nil, forKey: "string")
        store.setArray(Optional<[String]>.none, forKey: "array")
        #expect(store.getString(forKey: "string", default: nil) == nil)
        #expect(store.getArray(forKey: "array", default: ["fallback"]) == ["fallback"])
    }

    @Test
    func appValuesPersistsDefaultsThemeAndFirstRunState() {
        let values = DefaultAppValues(valueStore: makeStore())
        let income = Category(name: "Consulting", transactionType: .income, imageName: "dollarsign.circle.fill", rgbColor: "#00FF00")
        let expense = Category(name: "Transport", transactionType: .expense, imageName: "car.fill", rgbColor: "#0000FF")
        let account = Account(name: "Checking", imageName: "creditcard.fill", rgbColor: "0.29, 0.52, 1.0, 1.0")

        #expect(values.getAndUpdateIsFirstRun())
        #expect(!values.getAndUpdateIsFirstRun())

        values.set(incomeCategory: income)
        values.set(expenseCategory: expense)
        values.set(account: account)
        values.set(theme: .default)

        #expect(values.incomeCategory() == income)
        #expect(values.expenseCategory() == expense)
        #expect(values.account() == account)
        #expect(values.theme() == .default)

        let defaults = values.transactionDefaults()
        #expect(defaults.incomeCategory == income)
        #expect(defaults.expenseCategory == expense)
        #expect(defaults.account == account)
    }
}
