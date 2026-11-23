import XCTest

final class PlantStoryUITests: XCTestCase {
    func testCombinedStoryShowsCareAndObservationAndReflectsEdits() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Story fern")
        app.buttons["plants.save"].tap()
        let row = app.descendants(matching: .any)["plants.row.Story fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["plantDetail.journal"].tap()
        app.buttons["journal.story"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["story.empty"].waitForExistence(timeout: 5))
        app.buttons["story.add"].tap()
        let note = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("A small change noticed")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["A small change noticed"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "story.edit.")).firstMatch.tap()
        let edit = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5)); edit.tap(); edit.typeText("More: ")
        let expected = (edit.value as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(expected.contains("A small change noticed")); XCTAssertTrue(expected.contains("More:"))
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts[expected].waitForExistence(timeout: 5))
        // Return via the existing source screens to record care, then revisit the projection.
        app.tabBars.buttons["My Plants"].tap()
        let returnRow = app.descendants(matching: .any)["plants.row.Story fern"]
        XCTAssertTrue(returnRow.waitForExistence(timeout: 5)); returnRow.tap()
        XCTAssertTrue(app.buttons["plantDetail.care"].waitForExistence(timeout: 5))
        app.buttons["plantDetail.care"].tap()
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let careSavePreview = app.alerts["Review care changes"]
        XCTAssertTrue(careSavePreview.waitForExistence(timeout: 5))
        careSavePreview.buttons["Save changes"].tap()
        let recordCare = app.buttons["care.complete.Watering"]
        XCTAssertTrue(recordCare.waitForExistence(timeout: 5))
        // The care routine section sits below the guidance and reminder sections.
        // Explicitly scroll the List until the row is on-screen; XCTest's implicit
        // scroll-to-visible can return a {-1, -1} hit point for this nested button.
        for _ in 0..<5 {
            if recordCare.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(recordCare.isHittable, "The Watering record-care button should be visible before tapping.")
        recordCare.tap()
        let careNote = app.textFields["care.note"]
        XCTAssertTrue(careNote.waitForExistence(timeout: 5)); careNote.tap(); careNote.typeText("Checked before recording")
        app.buttons["care.recordSave"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["plantDetail.journal"].tap()
        app.buttons["journal.story"].tap()
        XCTAssertTrue(app.staticTexts["Recorded care"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Checked before recording"].exists)
        XCTAssertTrue(app.staticTexts[expected].exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Plant story combines care and journal"
        image.lifetime = .keepAlways; add(image)
    }
}
