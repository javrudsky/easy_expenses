//
//  EasyExpensesUITests.swift
//  EasyExpensesUITests
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import XCTest

final class EasyExpensesUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testCreateTransactionManuallyFromTransactionsView() throws {
        let app = XCUIApplication()
        app.launch()

        let transactionsTab = app.tabBars.buttons["Transactions"]
        XCTAssertTrue(transactionsTab.waitForExistence(timeout: 5))
        transactionsTab.tap()

        let addButton = app.buttons["add-transaction"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let amountField = app.textFields["transaction-amount"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        amountField.tap()
        amountField.typeText("12.34")

        let detail = "Manual UI test transaction"
        let detailEditor = app.textViews["transaction-detail"]
        XCTAssertTrue(detailEditor.waitForExistence(timeout: 5))
        detailEditor.tap()
        detailEditor.typeText(detail)

        let saveButton = app.buttons["save-transaction"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts[detail].waitForExistence(timeout: 5))
    }

}
