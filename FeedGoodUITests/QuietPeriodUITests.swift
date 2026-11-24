import XCTest

final class QuietPeriodUITests: XCTestCase {
    func testCreateAndEndOpenEndedQuietPeriodWithoutBlockingJournal() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Quiet fern")
        app.buttons["plants.save"].tap()

        let row = app.descendants(matching: .any)["plants.row.Quiet fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        app.buttons["plantDetail.care"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let savePreview = app.alerts["Review care changes"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 5))
        savePreview.buttons["Save changes"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let quietPeriodLink = app.buttons["plantDetail.quietPeriod"]
        XCTAssertTrue(quietPeriodLink.waitForExistence(timeout: 5))
        quietPeriodLink.tap()

        XCTAssertTrue(app.staticTexts["Before you confirm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quietPeriod.confirm"].exists)
        app.buttons["quietPeriod.confirm"].tap()

        XCTAssertTrue(app.staticTexts["Current Quiet Period"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quietPeriod.end"].exists)

        app.buttons["Close"].tap()
        app.buttons["plantDetail.journal"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Quiet Period active while journal remains available"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
