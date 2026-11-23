import XCTest

final class WhatsNewUITests: XCTestCase {
    func testWhatsNewSheetAppearsAfterUpdateAndOnlyOnce() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING", "FEEDGOOD_WHATS_NEW_LAST_SEEN", "0.0.9 (9)"]
        app.launch()

        XCTAssertTrue(app.staticTexts["whatsNew.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["whatsNew.highlight.0"].exists)
        let continueButton = app.buttons["whatsNew.continue"]
        XCTAssertTrue(continueButton.exists)
        continueButton.tap()
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2) == false)

        // Relaunch without the seed: the version was recorded as seen, so the
        // sheet stays away.
        let relaunched = XCUIApplication()
        relaunched.launchArguments = ["FEEDGOOD_UI_TESTING"]
        relaunched.launch()
        XCTAssertTrue(relaunched.staticTexts["whatsNew.title"].waitForExistence(timeout: 2) == false)
        XCTAssertTrue(relaunched.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testWhatsNewSheetDoesNotAppearOnFreshInstall() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING", "FEEDGOOD_WHATS_NEW_FRESH_INSTALL"]
        app.launch()

        XCTAssertTrue(app.staticTexts["whatsNew.title"].waitForExistence(timeout: 2) == false)
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }
}
