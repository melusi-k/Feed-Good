import XCTest

final class CareRoutineReviewUITests: XCTestCase {
    func testReviewIsReadOnlyAndSaveRequiresImpactConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()

        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Review fern")
        app.buttons["plants.save"].tap()

        let row = app.descendants(matching: .any)["plants.row.Review fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.buttons["plantDetail.routineReview"].tap()
        XCTAssertTrue(app.staticTexts["No care routines yet"].waitForExistence(timeout: 5))

        app.buttons["careReview.addTask"].tap()
        XCTAssertTrue(app.buttons["care.taskSave"].waitForExistence(timeout: 5))
        app.buttons["care.taskSave"].tap()
        let firstPreview = app.alerts["Review care changes"]
        XCTAssertTrue(firstPreview.waitForExistence(timeout: 5))
        XCTAssertTrue(firstPreview.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Repeat every 7 days")).firstMatch.exists)
        firstPreview.buttons["Cancel"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["No care routines yet"].waitForExistence(timeout: 5))

        app.buttons["careReview.addTask"].tap()
        app.buttons["care.taskSave"].tap()
        let savePreview = app.alerts["Review care changes"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 5))
        savePreview.buttons["Save changes"].tap()

        let taskRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "careReview.task.")).firstMatch
        XCTAssertTrue(taskRow.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Every 7 days")).firstMatch.exists)

        taskRow.tap()
        let stepper = app.steppers.firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons["Increment"].tap()
        app.buttons["care.taskSave"].tap()
        let editPreview = app.alerts["Review care changes"]
        XCTAssertTrue(editPreview.waitForExistence(timeout: 5))
        XCTAssertTrue(editPreview.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Repeat every 8 days")).firstMatch.exists)
        editPreview.buttons["Cancel"].tap()
        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Every 7 days")).firstMatch.waitForExistence(timeout: 5))
    }
}
