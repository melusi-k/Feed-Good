import XCTest

final class PlantScheduledCareAnalyticsUITests: XCTestCase {
    func testPlantProfileOpensScheduledCareAnalyticsWithExplicitSparseState() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Analytics fern")
        app.buttons["plants.save"].tap()

        let plantRow = app.descendants(matching: .any)["plants.row.Analytics fern"]
        XCTAssertTrue(plantRow.waitForExistence(timeout: 5))
        plantRow.tap()

        let analyticsLink = app.buttons["plantDetail.scheduledCareAnalytics"]
        XCTAssertTrue(analyticsLink.waitForExistence(timeout: 5))
        analyticsLink.tap()

        XCTAssertTrue(app.staticTexts["Scheduled outcomes · 30 days"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Completion rate"].exists)
        // The empty-history row is below the initial viewport in this List.
        // Scroll it into the accessibility tree before asserting its identifier.
        // The consistency section is above the opportunity history; scroll it
        // into the accessibility tree first, then continue to the empty state.
        app.swipeUp()
        let consistency = app.staticTexts["Care consistency"]
        XCTAssertTrue(consistency.waitForExistence(timeout: 5))
        let consistencyEmpty = app.descendants(matching: .any)["scheduledCareAnalytics.consistency.empty"]
        XCTAssertTrue(consistencyEmpty.exists)

        app.swipeUp()

        let emptyHistory = app.descendants(matching: .any)["scheduledCareAnalytics.emptyHistory"]
        XCTAssertTrue(emptyHistory.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[
            "A completion rate will appear when this period has completed or definitively overdue opportunities."
        ].exists)
    }

    func testCompletedScheduledCareShowsTaskScopedCurrentAndLongestStreak() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Streak fern")
        app.buttons["plants.save"].tap()

        let plantRow = app.descendants(matching: .any)["plants.row.Streak fern"]
        XCTAssertTrue(plantRow.waitForExistence(timeout: 5))
        plantRow.tap()

        app.buttons["plantDetail.care"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let savePreview = app.alerts["Review care changes"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 5))
        savePreview.buttons["Save changes"].tap()

        let complete = app.buttons["care.complete.Watering"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        XCTAssertTrue(app.buttons["care.recordSave"].waitForExistence(timeout: 5))
        app.buttons["care.recordSave"].tap()

        // Return to Plant Detail and open the existing scheduled-care entry point.
        let back = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        let analyticsLink = app.buttons["plantDetail.scheduledCareAnalytics"]
        XCTAssertTrue(analyticsLink.waitForExistence(timeout: 5))
        analyticsLink.tap()

        app.swipeUp()
        let streakRow = app.descendants(matching: .any)
            .matching(NSPredicate(
                format: "identifier BEGINSWITH %@",
                "scheduledCareAnalytics.consistency."
            ))
            .firstMatch
        XCTAssertTrue(streakRow.waitForExistence(timeout: 5))
        let rowLabel = streakRow.label
        XCTAssertTrue(rowLabel.contains("Watering"), "The streak must retain its care-task label: \(rowLabel)")
        XCTAssertTrue(rowLabel.contains("Completed in a row: 1"), "Expected the current run in the row: \(rowLabel)")
        XCTAssertTrue(rowLabel.contains("Longest run: 1"), "Expected the longest run in the row: \(rowLabel)")
    }

}
