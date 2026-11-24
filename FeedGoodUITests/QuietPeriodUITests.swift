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

        XCTAssertTrue(app.buttons["quietPeriod.confirm"].waitForExistence(timeout: 5))
        app.buttons["quietPeriod.confirm"].tap()

        // Creation saves and dismisses back to the plant profile.
        XCTAssertTrue(app.buttons["plantDetail.quietPeriod"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["plantDetail.quietPeriod"].label, "Manage Quiet Period")

        // A Quiet Period must not block the plant journal.
        app.buttons["plantDetail.journal"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Reopen management to verify the active period and its end control.
        app.buttons["plantDetail.quietPeriod"].tap()
        XCTAssertTrue(app.buttons["quietPeriod.end"].waitForExistence(timeout: 5))
        app.buttons["quietPeriod.end"].tap()
        XCTAssertTrue(app.buttons["plantDetail.care"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Quiet Period active while journal remains available"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
