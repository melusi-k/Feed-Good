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
        XCTAssertTrue(edit.waitForExistence(timeout: 5)); edit.tap(); edit.typeText(" and another")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["A new leaf today and another"].waitForExistence(timeout: 5))
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = "Journal saved entry"; image.lifetime = .keepAlways; self.add(image)
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.delete.")).firstMatch.tap()
        app.buttons["Delete entry"].tap()
        XCTAssertTrue(app.staticTexts["Remember a little moment"].waitForExistence(timeout: 5))
    }
}
