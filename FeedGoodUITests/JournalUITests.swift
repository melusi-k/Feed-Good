import XCTest

final class JournalUITests: XCTestCase {
    func testAddEditAndDeleteGardenJournalEntry() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Journal fern")
        app.buttons["plants.save"].tap()
        app.tabBars.buttons["Journal"].tap()
        let add = app.buttons["journal.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5)); add.tap()
        let note = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("A new leaf today")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["A new leaf today"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.edit.")).firstMatch.tap()
        let edit = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        edit.typeText(" and another")
        let editedValue = edit.value as? String ?? ""
        XCTAssertTrue(editedValue.contains("A new leaf today"))
        XCTAssertTrue(editedValue.contains("and another"))
        XCTAssertNotEqual(editedValue, "A new leaf today")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts[editedValue.trimmingCharacters(in: .whitespacesAndNewlines)].waitForExistence(timeout: 5))
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = "Journal saved entry"; image.lifetime = .keepAlways; self.add(image)
        XCTAssertFalse(app.buttons["journal.export"].exists)
        XCTAssertFalse(app.buttons["journal.recover"].exists)
        XCTAssertFalse(app.staticTexts["journal.archiveScope"].exists)
        XCTAssertFalse(app.staticTexts["journal.recoveryPolicy"].exists)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["journal.export"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["journal.recover"].exists)
        XCTAssertTrue(app.staticTexts["journal.archiveScope"].exists)
        // iOS 26 materializes lazy Form rows only once they scroll into view;
        // the recovery-policy note sits below the fold, so scroll it on
        // screen before expecting it.
        var settingsScrolls = 0
        while app.staticTexts["journal.recoveryPolicy"].exists == false, settingsScrolls < 8 {
            app.swipeUp()
            settingsScrolls += 1
        }
        XCTAssertTrue(app.staticTexts["journal.recoveryPolicy"].exists)
        let settingsImage = XCTAttachment(screenshot: app.screenshot())
        settingsImage.name = "Settings journal archive controls"
        settingsImage.lifetime = .keepAlways
        self.add(settingsImage)
        app.tabBars.buttons["Journal"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.delete.")).firstMatch.tap()
        app.buttons["Delete entry"].tap()
        XCTAssertTrue(app.staticTexts["Remember a little moment"].waitForExistence(timeout: 5))
    }
}
