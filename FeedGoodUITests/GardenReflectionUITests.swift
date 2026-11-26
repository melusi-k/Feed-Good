import XCTest

/// Weekly garden reflection journeys. Alphabetical order matters: the empty
/// and dismissal cases must run before anything records care in this garden.
final class GardenReflectionUITests: XCTestCase {
    func testDismissTucksTheCardAwayAndShowAgainRestoresIt() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()

        let card = app.descendants(matching: .any)["reflection.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        app.buttons["reflection.dismiss"].tap()
        XCTAssertFalse(card.waitForExistence(timeout: 2))
        let reopen = app.buttons["reflection.reopen"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 5))
        reopen.tap()
        XCTAssertTrue(app.descendants(matching: .any)["reflection.card"].waitForExistence(timeout: 5))
    }

    func testEmptyWeekStaysNeutralAndOffersAPrompt() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()

        XCTAssertTrue(app.staticTexts["reflection.empty"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A quiet week so far. Nothing recorded yet, and that is fine."].exists)
        XCTAssertTrue(app.staticTexts["reflection.prompt"].exists)
        // No failure language, no score, no look-back list for an empty week.
        XCTAssertFalse(app.buttons["reflection.lookBack"].exists)
    }

    func testRecordedCareAppearsAsAMomentAndOpensItsPlant() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()

        // Plant + routine + one recorded care event, all through the real UI.
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Reflection fern")
        app.buttons["plants.save"].tap()
        let row = app.descendants(matching: .any)["plants.row.Reflection fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["plantDetail.care"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let savePreview = app.alerts["Review care changes"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 5))
        savePreview.buttons["Save changes"].tap()
        let complete = app.buttons["care.complete.Watering"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5)); complete.tap()
        app.buttons["care.recordSave"].tap()

        // The reflection derives from that real record.
        app.tabBars.buttons["Today"].tap()
        let summary = app.staticTexts["reflection.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 moment of care this week, all for Reflection fern."].exists)

        // Look back shows the moment; tapping it opens the source plant.
        app.buttons["reflection.lookBack"].tap()
        let moment = app.buttons["reflection.moment.0"]
        XCTAssertTrue(moment.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Watering recorded for Reflection fern"].exists)
        moment.tap()
        XCTAssertTrue(app.buttons["plantDetail.care"].waitForExistence(timeout: 5))
    }
}
