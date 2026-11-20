import XCTest

enum UITestFixture: String {
    case empty
    case november
    case many
    case manyCategories = "many-categories"
    case large
}

@MainActor
enum TestAppLauncher {
    static func launch(fixture: UITestFixture = .empty,
                       ownedProducts: [String] = [],
                       transcript: String? = nil,
                       extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-test-fixture=\(fixture.rawValue)",
            "--ui-test-now=2026-11-19T12:00:00Z",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        if !ownedProducts.isEmpty {
            app.launchArguments.append("--ui-test-products=\(ownedProducts.joined(separator: ","))")
        }
        if let transcript {
            app.launchArguments.append("--ui-test-transcript=\(transcript)")
        }
        app.launchArguments.append(contentsOf: extraArguments)
        app.launch()
        return app
    }
}

@MainActor
enum UIWait {
    static let timeout: TimeInterval = 8

    static func exists(_ element: XCUIElement, timeout: TimeInterval = UIWait.timeout) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
}

@MainActor
struct MainTabsPage {
    let app: XCUIApplication

    func open(_ tab: String) {
        app.tabBars.buttons[tab].tap()
    }
}

@MainActor
struct TransactionsPage {
    let app: XCUIApplication

    var addButton: XCUIElement { app.buttons["add-transaction"] }
    var searchField: XCUIElement { app.textFields["transactions.searchField"] }
    var totalBalance: XCUIElement { app.descendants(matching: .any)["transactions.totalBalance"] }
    var list: XCUIElement { app.descendants(matching: .any)["transactions.list"] }

    func open() {
        app.tabBars.buttons["Transactions"].tap()
    }

    func row(id: String) -> XCUIElement {
        app.descendants(matching: .any)["transactions.row.\(id)"]
    }

    func row(detail: String) -> XCUIElement {
        app.staticTexts[detail]
    }
}

@MainActor
struct TransactionEditorPage {
    let app: XCUIApplication

    var amount: XCUIElement { app.textFields["transaction-amount"] }
    var detail: XCUIElement { app.textViews["transaction-detail"] }
    var saveButton: XCUIElement { app.buttons["save-transaction"] }

    func selectType(_ type: String) {
        let identifier = type == "Income"
            ? "transactionEditor.incomeType"
            : "transactionEditor.expenseType"
        app.buttons[identifier].tap()
    }

    func replaceAmount(with value: String) {
        amount.tap()
        amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 40))
        amount.typeText(value)
    }

    func enterDetail(_ value: String) {
        detail.tap()
        detail.typeText(value)
    }
}

@MainActor
struct ReportsPage {
    let app: XCUIApplication

    var periodSelector: XCUIElement {
        app.descendants(matching: .any)["reports.periodSelector"]
    }

    func open() {
        app.tabBars.buttons["Reports"].tap()
    }

    func report(_ slug: String) -> XCUIElement {
        app.buttons["reports.item.\(slug)"]
    }
}

@MainActor
struct SettingsPage {
    let app: XCUIApplication

    var groupingPicker: XCUIElement { app.descendants(matching: .any)["settings.transactionGrouping"] }

    func open() {
        app.tabBars.buttons["Settings"].tap()
    }
}
