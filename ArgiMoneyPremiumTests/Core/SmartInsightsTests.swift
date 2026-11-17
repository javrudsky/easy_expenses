import Foundation
import Testing
@testable import ArgiMoneyPremium

@Suite("Smart insights")
struct SmartInsightsTests {
    private let food = Category(name: "Food",
                                transactionType: .expense,
                                imageName: "fork.knife",
                                rgbColor: "0.72, 0.27, 0.85, 1.0")
    private let salary = Category(name: "Salary",
                                  transactionType: .income,
                                  imageName: "dollarsign.circle.fill",
                                  rgbColor: "0.10, 0.64, 0.33, 1.0")
    private let cash = Account(name: "Cash",
                               imageName: "creditcard.fill",
                               rgbColor: "0.29, 0.52, 1.0, 1.0")

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var range: ReportRange {
        ReportRange(start: calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
                    endExclusive: calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!)
    }

    private func date(day: Int) -> TimeInterval {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day))!.timeIntervalSince1970
    }

    private var analytics: ReportAnalytics {
        let transactions = [
            Transaction(id: UUID(),
                        date: date(day: 5),
                        category: salary,
                        detail: nil,
                        transactionType: .income,
                        account: cash,
                        amount: 1_000),
            Transaction(id: UUID(),
                        date: date(day: 10),
                        category: food,
                        detail: "Groceries",
                        transactionType: .expense,
                        account: cash,
                        amount: 300)
        ]
        let dataset = ReportDataset(transactions: transactions,
                                    categories: [food, salary],
                                    accounts: [cash],
                                    budgets: [ReportBudget(categoryID: food.id, amount: 100)])
        return ReportAnalytics(dataset: dataset, range: range)
    }

    @Test
    func promptKeepsTheRequestedBasePromptAndSummarizesThePeriod() {
        let prompt = SmartInsightsPrompt.make(analytics: analytics,
                                              locale: Locale(identifier: "en_US"))

        #expect(prompt.hasPrefix(SmartInsightsPrompt.basePrompt))
        #expect(prompt.contains("Total income"))
        #expect(prompt.contains("Total expenses"))
        #expect(prompt.contains("Savings rate"))
        #expect(prompt.contains("Food"))
        #expect(prompt.contains("%"))
        #expect(prompt.contains("over budget"))
        #expect(!prompt.contains("Groceries"))
    }

    @Test
    func promptExplainsWhenThereIsNoIncome() {
        let dataset = ReportDataset(transactions: [analytics.dataset.transactions[1]],
                                    categories: [food, salary],
                                    accounts: [cash],
                                    budgets: [])
        let prompt = SmartInsightsPrompt.make(analytics: ReportAnalytics(dataset: dataset, range: range),
                                              locale: Locale(identifier: "en_US"))

        #expect(prompt.contains("Savings rate: not available"))
    }

    @Test
    func requestKeyChangesWithTheSelectedPeriod() {
        let first = SmartInsightsRequestKey(analytics: analytics)
        let same = SmartInsightsRequestKey(analytics: analytics)
        let other = SmartInsightsRequestKey(
            analytics: ReportAnalytics(dataset: analytics.dataset,
                                       range: ReportRange(start: range.start,
                                                          endExclusive: range.start.addingTimeInterval(86_400)))
        )

        #expect(first == same)
        #expect(first != other)
    }

    @Test
    func unavailabilityExplainsWhetherTheModelCanBeDownloaded() {
        #expect(FoundationModelAvailability.UnavailabilityReason.deviceNotEligible.canBeDownloaded == false)
        #expect(FoundationModelAvailability.UnavailabilityReason.deviceNotEligible.needsSettingsAction == false)
        #expect(FoundationModelAvailability.UnavailabilityReason.modelNotReady.canBeDownloaded)
        #expect(FoundationModelAvailability.UnavailabilityReason.appleIntelligenceNotEnabled.canBeDownloaded)
        #expect(FoundationModelAvailability.UnavailabilityReason.appleIntelligenceNotEnabled.needsSettingsAction)
    }

    @Test
    func languageFollowsTheDeviceLocale() {
        #expect(FoundationModelLanguage.preferred(for: Locale(identifier: "es_AR")) == .spanish)
        #expect(FoundationModelLanguage.preferred(for: Locale(identifier: "en_US")) == .english)
        #expect(FoundationModelLanguage.spanish.instruction.contains("Spanish"))
    }
}
