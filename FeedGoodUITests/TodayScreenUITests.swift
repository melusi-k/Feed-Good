import XCTest

final class TodayScreenUITests: XCTestCase {
    func testTodayScreenIntroducesTheGardenAndOffersAFirstStep() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["today.dailyThought"].exists)
        XCTAssertTrue(app.buttons["today.careCheckIn.action"].exists)
        XCTAssertTrue(app.staticTexts["Make room for a little green"].exists)
    }

    func testAppearanceCanBeChangedAndPersistsInSettings() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let appearancePicker = app.descendants(matching: .any)["settings.appearance"]
        XCTAssertTrue(appearancePicker.waitForExistence(timeout: 5))

        let darkOption = app.buttons["Dark"]
        XCTAssertTrue(darkOption.waitForExistence(timeout: 3))
        darkOption.tap()
        XCTAssertTrue(app.staticTexts["Dark appearance"].exists)

        app.buttons["Light"].tap()
        XCTAssertTrue(app.staticTexts["Light appearance"].exists)

        app.buttons["System"].tap()
        XCTAssertTrue(app.staticTexts["System appearance"].exists)
    }
}
