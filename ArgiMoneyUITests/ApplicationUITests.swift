import XCTest

/// UI acceptance tests migrated to XCTest for compatibility with UI test target.
final class ApplicationUITests: XCTestCase {

    // MARK: - NAV

    @MainActor
    func test_NAV_001_clean_isolated_launch() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }

        XCTAssertTrue(UIWait.exists(app.tabBars.buttons["Record"]))
        XCTAssertTrue(UIWait.exists(app.tabBars.buttons["Transactions"]))
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["home.recordButton"]))
    }

    @MainActor
    func test_NAV_002_recording_screen_exposes_primary_controls_and_balances() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }

        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["home.monthlySummary"]))
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["home.incomeTotal"]))
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["home.expenseTotal"]))
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["home.recordButton"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Tell me about your transaction"]))
    }

    @MainActor
    func test_NAV_003_main_tabs_open_their_destinations() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }
        let tabs = MainTabsPage(app: app)

        for name in ["Transactions", "Reports", "Settings", "More", "Record"] {
            let tab = app.tabBars.buttons[name]
            XCTAssertTrue(UIWait.exists(tab))
            tabs.open(name)
            XCTAssertTrue(tab.isSelected)
        }
    }

    @MainActor
    func test_NAV_006_empty_state_navigation_does_not_crash() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }

        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(UIWait.exists(app.buttons["add-transaction"]))
        app.tabBars.buttons["Reports"].tap()
        XCTAssertTrue(UIWait.exists(app.buttons["reports.item.income-&-expenses"]))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(UIWait.exists(app.navigationBars["Settings"]))
        app.tabBars.buttons["More"].tap()
        XCTAssertTrue(UIWait.exists(app.navigationBars["More"]))
    }

    // MARK: - Transactions

    @MainActor
    func test_TX_001_empty_list_has_add_action_and_zero_balances() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()

        XCTAssertTrue(UIWait.exists(page.addButton))
        XCTAssertTrue(UIWait.exists(page.list))
        XCTAssertEqual(transactionRows(in: app).count, 0)
        XCTAssertTrue(app.descendants(matching: .any)["transactions.incomeTotal"].label.contains("0"))
        XCTAssertTrue(app.descendants(matching: .any)["transactions.expenseTotal"].label.contains("0"))
    }

    @MainActor
    func test_TX_002_seeded_November_transactions_visible_and_October_excluded_from_month_summary() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()

        XCTAssertTrue(UIWait.exists(page.row(id: "00000000-0000-0000-0000-000000001001")))
        XCTAssertTrue(UIWait.exists(page.row(detail: "Supermarket")))
        XCTAssertTrue(UIWait.exists(page.row(detail: "Fuel")))
        XCTAssertTrue(UIWait.exists(page.row(detail: "Restaurant")))
        XCTAssertTrue(UIWait.exists(page.row(detail: "Freelance work")))
        XCTAssertTrue(UIWait.exists(page.row(detail: "Groceries")))
        XCTAssertEqual(transactionRows(in: app).count, 6)
        XCTAssertTrue(app.descendants(matching: .any)["transactions.incomeTotal"].label.contains("190"))
        XCTAssertTrue(app.descendants(matching: .any)["transactions.expenseTotal"].label.contains("45"))
    }

    @MainActor
    func test_TX_003_create_income_transaction() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }
        TransactionsPage(app: app).open()
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["transactions.dataReady"]))
        app.buttons["add-transaction"].tap()

        let editor = TransactionEditorPage(app: app)
        editor.selectType("Income")
        editor.amount.tap()
        editor.amount.typeText("150000")
        editor.enterDetail("UI test income")
        editor.saveButton.tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["UI test income"]))
        XCTAssertTrue(app.descendants(matching: .any)["transactions.incomeTotal"].label.contains("150"))
    }

    @MainActor
    func test_TX_004_create_expense_transaction() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }
        TransactionsPage(app: app).open()
        app.buttons["add-transaction"].tap()

        let editor = TransactionEditorPage(app: app)
        editor.amount.tap()
        editor.amount.typeText("25000")
        editor.enterDetail("UI test expense")
        editor.saveButton.tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["UI test expense"]))
        XCTAssertTrue(app.descendants(matching: .any)["transactions.expenseTotal"].label.contains("25"))
    }

    @MainActor
    func test_TX_005_editing_seeded_transaction_updates_row_without_duplicate() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()
        let id = "00000000-0000-0000-0000-000000001002"
        page.row(id: id).tap()

        let editor = TransactionEditorPage(app: app)
        editor.replaceAmount(with: "1800")
        editor.saveButton.tap()

        XCTAssertTrue(UIWait.exists(page.row(id: id)))
        XCTAssertEqual(transactionRows(in: app).count, 6)
        XCTAssertTrue(page.row(id: id).label.contains("1,800"))
        XCTAssertTrue(UIWait.exists(page.row(detail: "Supermarket")))
    }

    @MainActor
    func test_TX_006_changing_transaction_category_updates_row() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()
        page.row(id: "00000000-0000-0000-0000-000000001002").tap()
        app.buttons["Transport"].tap()
        app.buttons["save-transaction"].tap()

        XCTAssertTrue(UIWait.exists(page.row(detail: "Supermarket")))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Transport"]))
    }

    @MainActor
    func test_TX_009_search_filters_by_transaction_detail() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()
        page.searchField.tap()
        page.searchField.typeText("Supermarket")

        XCTAssertTrue(UIWait.exists(page.row(detail: "Supermarket")))
        XCTAssertFalse(page.row(detail: "Fuel").exists)
    }

    @MainActor
    func test_TX_007_delete_transaction_removes_row_and_updates_list() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()
        let id = "00000000-0000-0000-0000-000000001002"
        let row = page.row(id: id)
        XCTAssertTrue(UIWait.exists(row))
        row.swipeLeft()
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(UIWait.exists(delete))
        delete.tap()

        XCTAssertFalse(row.waitForExistence(timeout: 1))
        XCTAssertEqual(transactionRows(in: app).count, 5)
    }

    @MainActor
    func test_TX_014_large_transaction_amounts_remain_available_in_UI() {
        let app = TestAppLauncher.launch(fixture: .large)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()

        XCTAssertTrue(UIWait.exists(page.row(detail: "Large balance")))
        XCTAssertTrue(UIWait.exists(page.totalBalance))
        XCTAssertTrue(page.totalBalance.frame.width > 0)
    }

    @MainActor
    func test_TX_015_fixed_transaction_header_remains_present_when_scrolling_long_list() {
        let app = TestAppLauncher.launch(fixture: .many)
        defer { app.terminate() }
        let page = TransactionsPage(app: app)
        page.open()

        let list = page.list
        XCTAssertTrue(UIWait.exists(list))
        list.swipeUp()
        XCTAssertTrue(UIWait.exists(page.totalBalance))
        XCTAssertTrue(UIWait.exists(page.searchField))
    }

    @MainActor
    func test_TX_011_012_transaction_grouping_preference_changes() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        SettingsPage(app: app).open()

        let picker = app.descendants(matching: .any)["settings.transactionGrouping"]
        XCTAssertTrue(UIWait.exists(picker))
        picker.tap()
        let byDay = app.buttons["By day"]
        if UIWait.exists(byDay) { byDay.tap() }
        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(UIWait.exists(app.staticTexts["November 12, 2026"]))

        app.tabBars.buttons["Settings"].tap()
        picker.tap()
        let byMonth = app.buttons["By month"]
        if UIWait.exists(byMonth) { byMonth.tap() }
        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(UIWait.exists(app.staticTexts["November 2026"]))
    }

    @MainActor
    func test_TX_012_group_transactions_by_month() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        SettingsPage(app: app).open()
        let picker = app.descendants(matching: .any)["settings.transactionGrouping"]
        XCTAssertTrue(UIWait.exists(picker))
        picker.tap()
        let byMonth = app.buttons["By month"]
        XCTAssertTrue(UIWait.exists(byMonth))
        byMonth.tap()
        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(UIWait.exists(app.staticTexts["November 2026"]))
    }

    @MainActor
    func test_SET_002_grouping_preference_changes_transactions_screen() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        SettingsPage(app: app).open()
        let picker = app.descendants(matching: .any)["settings.transactionGrouping"]
        XCTAssertTrue(UIWait.exists(picker))
        picker.tap()
        let byMonth = app.buttons["By month"]
        XCTAssertTrue(UIWait.exists(byMonth))
        byMonth.tap()

        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(UIWait.exists(app.staticTexts["November 2026"]))
    }

    // MARK: - Reports

    @MainActor
    func test_REP_001_reports_dashboard_offers_free_and_premium() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        ReportsPage(app: app).open()

        XCTAssertTrue(UIWait.exists(app.buttons["reports.item.income-&-expenses"]))
        XCTAssertTrue(UIWait.exists(app.buttons["reports.item.expenses-by-category"]))
        XCTAssertTrue(UIWait.exists(app.buttons["reports.item.cash-flow-analysis"]))
    }

    @MainActor
    func test_REP_012_locked_cash_flow_report_displays_premium_gate() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        let report = reports.report("cash-flow-analysis")
        XCTAssertTrue(UIWait.exists(report))
        report.tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Premium Report"]))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Unlock")).firstMatch.exists)
    }

    @MainActor
    func test_REP_002_income_and_expense_report_uses_fixture_totals() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        let report = reports.report("income-&-expenses")
        XCTAssertTrue(UIWait.exists(report))
        report.tap()

        XCTAssertTrue(UIWait.exists(reports.periodSelector))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Income vs. Expenses"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Period Summary"]))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "145")).firstMatch.exists)
    }

    @MainActor
    func test_REP_003_expenses_by_category_report_presents_seeded_categories() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        let report = reports.report("expenses-by-category")
        XCTAssertTrue(UIWait.exists(report))
        report.tap()

        XCTAssertTrue(UIWait.exists(reports.periodSelector))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Food"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Transport"]))
    }

    @MainActor
    func test_REP_004_current_month_period_excludes_October_fixture_transaction() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        reports.report("income-&-expenses").tap()

        XCTAssertTrue(UIWait.exists(reports.periodSelector))
        XCTAssertTrue(app.descendants(matching: .any)["reports.metric.income.amount"].label.contains("190"))
        XCTAssertTrue(app.descendants(matching: .any)["reports.metric.expenses.amount"].label.contains("45"))
    }

    @MainActor
    func test_REP_005_this_year_includes_November_and_October_fixtures() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        reports.report("income-&-expenses").tap()
        app.buttons["reports.period.year"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["reports.metric.income.amount"].label.contains("190"))
        XCTAssertTrue(app.descendants(matching: .any)["reports.metric.expenses.amount"].label.contains("60"))
        XCTAssertTrue(app.descendants(matching: .any)["reports.metric.net.amount"].label.contains("130"))
    }

    @MainActor
    func test_REP_008_unlocked_cash_flow_report_displays_chart_and_net_value() {
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: ["com.argimoney.report.cashflow"])
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        reports.report("cash-flow-analysis").tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Cash Flow Over Time"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Net Cash Flow"]))
    }

    @MainActor
    func test_REP_009_unlocked_spending_trends_report_shows_period_summaries() {
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: ["com.argimoney.report.spendingtrends"])
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        reports.report("spending-trends").tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Spending Over Time"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Period Breakdown"]))
    }

    @MainActor
    func test_REP_010_unlocked_account_analysis_report_shows_accounts_and_activity() {
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: ["com.argimoney.report.accountanalysis"])
        defer { app.terminate() }
        let reports = ReportsPage(app: app)
        reports.open()
        reports.report("account-analysis").tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["By Account"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Account Activity"]))
    }

    // MARK: - Data Transfer & IAP

    @MainActor
    func test_CSV_001_data_transfer_screen_offers_import_and_export() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Data Management"].tap()

        XCTAssertTrue(UIWait.exists(app.buttons["dataTransfer.exportButton"]))
        XCTAssertTrue(UIWait.exists(app.buttons["dataTransfer.importButton"]))
    }

    @MainActor
    func test_IAP_001_premium_store_shows_product_rows_and_restore_control() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Premium & Purchases"].tap()

        XCTAssertTrue(UIWait.exists(app.navigationBars["Premium"]))
        XCTAssertTrue(UIWait.exists(app.buttons["Restore Purchases"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Argi Premium"]))
    }

    // MARK: - Input

    @MainActor
    func test_INPUT_005_deterministic_speech_transcript_opens_populated_transaction_editor() {
        let app = TestAppLauncher.launch(fixture: .empty,
                                         transcript: "I spent 2500 on Food")
        defer { app.terminate() }
        let recordButton = app.descendants(matching: .any)["home.recordButton"]
        XCTAssertTrue(UIWait.exists(recordButton))
        recordButton.press(forDuration: 1.2)

        let amount = app.textFields["transaction-amount"]
        XCTAssertTrue(UIWait.exists(amount))
        XCTAssertTrue((amount.value as? String)?.contains("2500") == true)
        XCTAssertTrue(app.buttons["transactionEditor.expenseType"].isSelected)
    }

    @MainActor
    func test_INPUT_006_deterministic_spoken_income_opens_income_transaction() {
        let app = TestAppLauncher.launch(fixture: .empty,
                                         transcript: "I received 150000 salary")
        defer { app.terminate() }
        app.descendants(matching: .any)["home.recordButton"].press(forDuration: 1.2)

        let amount = app.textFields["transaction-amount"]
        XCTAssertTrue(UIWait.exists(amount))
        XCTAssertTrue((amount.value as? String)?.contains("150000") == true)
        XCTAssertTrue(app.buttons["transactionEditor.incomeType"].isSelected)
    }

    @MainActor
    func test_INPUT_012_expanded_category_search_selects_item() {
        let app = TestAppLauncher.launch(fixture: .manyCategories)
        defer { app.terminate() }
        TransactionsPage(app: app).open()
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["transactions.dataReady"]))
        app.buttons["add-transaction"].tap()

        let more = app.buttons["categories.moreButton"]
        XCTAssertTrue(UIWait.exists(more))
        more.tap()
        let search = app.textFields["categories.searchField"]
        XCTAssertTrue(UIWait.exists(search))
        search.tap()
        search.typeText("Extra expense 8")
        let choice = app.buttons["Extra expense 8"]
        XCTAssertTrue(UIWait.exists(choice))
        choice.tap()
        XCTAssertFalse(search.exists)
        XCTAssertTrue(UIWait.exists(app.staticTexts["Extra expense 8"]))
    }

    // MARK: - Categories

    @MainActor
    func test_CAT_002_create_custom_category_with_categories_entitlement() {
        let categoryProduct = "com.argimoney.module.categories"
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: [categoryProduct])
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Expense Categories"].tap()
        let add = app.buttons["Add Category"]
        XCTAssertTrue(UIWait.exists(add))
        add.tap()

        let name = app.textFields["categoryEditor.nameField"]
        XCTAssertTrue(UIWait.exists(name))
        name.tap()
        name.typeText("Pets")
        app.buttons["categoryEditor.saveButton"].tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Pets"]))
    }

    @MainActor
    func test_CAT_003_rename_existing_category() {
        let categoryProduct = "com.argimoney.module.categories"
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: [categoryProduct])
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Expense Categories"].tap()
        let foodID = "00000000-0000-0000-0000-000000000101"
        let row = app.descendants(matching: .any)["categories.row.\(foodID)"]
        XCTAssertTrue(UIWait.exists(row))
        row.tap()

        let name = app.textFields["categoryEditor.nameField"]
        XCTAssertTrue(UIWait.exists(name))
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 40))
        name.typeText("Pet Care")
        app.buttons["categoryEditor.saveButton"].tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Pet Care"]))
    }

    @MainActor
    func test_CAT_010_locked_category_module_presents_premium_gate_without_mutation() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Expense Categories"].tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Preview"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Expense Categories"]))
        XCTAssertFalse(app.buttons["Add Category"].exists)
    }

    // MARK: - Accounts

    @MainActor
    func test_ACC_002_create_account_with_accounts_module_entitlement() {
        let accountProduct = "com.argimoney.module.accounts"
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: [accountProduct])
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Accounts"].tap()
        let add = app.buttons["Add Account"]
        XCTAssertTrue(UIWait.exists(add))
        add.tap()

        let name = app.textFields["accountEditor.nameField"]
        XCTAssertTrue(UIWait.exists(name))
        name.tap()
        name.typeText("Savings")
        app.buttons["accountEditor.saveButton"].tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Savings"]))
    }

    @MainActor
    func test_ACC_001_account_module_shows_seeded_accounts() {
        let accountProduct = "com.argimoney.module.accounts"
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: [accountProduct])
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Accounts"].tap()

        XCTAssertTrue(UIWait.exists(app.staticTexts["Cash"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Bank"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Wallet"]))
    }

    @MainActor
    func test_ACC_005_deleting_account_used_by_transactions_reports_error() {
        let accountProduct = "com.argimoney.module.accounts"
        let app = TestAppLauncher.launch(fixture: .november,
                                         ownedProducts: [accountProduct])
        defer { app.terminate() }
        app.tabBars.buttons["More"].tap()
        app.buttons["Accounts"].tap()
        let bankID = "00000000-0000-0000-0000-000000000202"
        let bankRow = app.descendants(matching: .any)["accounts.row.\(bankID)"]
        XCTAssertTrue(UIWait.exists(bankRow))
        bankRow.swipeLeft()
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(UIWait.exists(delete))
        delete.tap()

        XCTAssertTrue(UIWait.exists(app.alerts["Unable to complete"]))
        XCTAssertTrue(UIWait.exists(app.staticTexts["Bank"]))
    }

    // MARK: - Errors / Accessibility

    @MainActor
    func test_ERR_006_main_controls_expose_stable_identifiers() {
        let app = TestAppLauncher.launch(fixture: .november)
        defer { app.terminate() }
        let homeRecord = app.descendants(matching: .any)["home.recordButton"]
        XCTAssertTrue(UIWait.exists(homeRecord))
        TransactionsPage(app: app).open()
        XCTAssertTrue(UIWait.exists(app.buttons["add-transaction"]))
        XCTAssertTrue(UIWait.exists(app.textFields["transactions.searchField"]))
        XCTAssertTrue(UIWait.exists(app.descendants(matching: .any)["transactions.list"]))
    }

    // MARK: - Helpers

    @MainActor
    private func transactionRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "transactions.row.")
        )
    }
}
