import XCTest

/// Minimal runner adapter for Xcode versions where UI-automation targets still
/// require XCTest discovery. The acceptance scenarios themselves are authored
/// with Swift Testing in `ApplicationUITests.swift`.
@MainActor
final class XCTestCompatibilityAdapter: XCTestCase {
    func testUIAutomationRunnerLaunchesTheApp() {
        let app = TestAppLauncher.launch(fixture: .empty)
        defer { app.terminate() }

        XCTAssertTrue(app.tabBars.buttons["Record"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["home.recordButton"].exists)
    }
}
