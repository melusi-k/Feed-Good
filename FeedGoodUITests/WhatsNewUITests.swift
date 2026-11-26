import XCTest

final class WhatsNewUITests: XCTestCase {
    func testWhatsNewAppearsAfterAnUpgradeAndCanBeAcknowledged() {
        let app = XCUIApplication()
        app.launchArguments = [
            "FEEDGOOD_UI_TESTING",
            "FEEDGOOD_WHATS_NEW_LAST_SEEN",
            "0.0.9 (9)"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["whatsNew.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["whatsNew.version"].exists)
        let continueButton = app.buttons["whatsNew.continue"]
        XCTAssertTrue(continueButton.exists)
        continueButton.tap()
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2) == false)
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testFreshInstallShowsOnboardingInsteadOfWhatsNew() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING", "FEEDGOOD_ONBOARDING_RESET"]
        app.launch()

        XCTAssertTrue(app.staticTexts["onboarding.title.0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["whatsNew.title"].waitForExistence(timeout: 1) == false)
    }
}
