import XCTest

final class CareRoutineUITests: XCTestCase {
    func testCreateRoutineRecordCareAndReadHistory() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Care fern")
        app.buttons["plants.save"].tap()
        let row = app.descendants(matching: .any)["plants.row.Care fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["plantDetail.care"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let complete = app.buttons["care.complete.Watering"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5)); complete.tap()
        let note = app.textFields["care.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("Checked the soil first")
        app.buttons["care.recordSave"].tap()
        XCTAssertTrue(app.staticTexts["Checked the soil first"].waitForExistence(timeout: 5))

        let historyRow = app.buttons["care.eventEdit.Watering"]
        XCTAssertTrue(historyRow.waitForExistence(timeout: 5))
        historyRow.tap()
        let eventNote = app.textFields["care.eventNote"]
        XCTAssertTrue(eventNote.waitForExistence(timeout: 5))
        XCTAssertTrue(app.datePickers["Completed"].exists)
        let originalNote = eventNote.value as? String ?? ""
        eventNote.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        eventNote.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: originalNote.count))
        eventNote.typeText("Corrected care note")
        app.buttons["care.eventSave"].tap()
        XCTAssertTrue(app.staticTexts["Corrected care note"].waitForExistence(timeout: 5))

        app.buttons["care.eventEdit.Watering"].tap()
        app.buttons["care.eventDelete"].tap()
        let deleteConfirmation = app.buttons["Delete record"]
        XCTAssertTrue(deleteConfirmation.waitForExistence(timeout: 5))
        deleteConfirmation.tap()
        XCTAssertFalse(app.staticTexts["Corrected care note"].waitForExistence(timeout: 2))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Care routine and saved history"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
