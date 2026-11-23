import XCTest

final class JournalMilestoneUITests: XCTestCase {
    func testCreateMilestoneOnlyThenRemoveLabelWhileKeepingNote() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Milestone fern")
        app.buttons["plants.save"].tap()
        app.tabBars.buttons["Journal"].tap()
        app.buttons["journal.add"].tap()
        let entryType = app.buttons["journal.entryType"]
        XCTAssertTrue(entryType.waitForExistence(timeout: 5)); entryType.tap()
        app.buttons["Milestone"].tap()
        XCTAssertTrue(app.buttons["journal.milestone"].waitForExistence(timeout: 5))
        app.buttons["journal.milestone"].tap()
        app.buttons["New leaf"].tap()
        XCTAssertTrue(app.buttons["journal.save"].isEnabled)
        app.buttons["journal.save"].tap()
        let milestone = app.staticTexts["journal.milestoneLabel"]
        XCTAssertTrue(milestone.waitForExistence(timeout: 5))
        XCTAssertTrue(milestone.label.contains("New leaf"))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Journal milestone observation"
        image.lifetime = .keepAlways; add(image)
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.edit.")).firstMatch.tap()
        let note = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("Kept observation")
        app.buttons["journal.milestone"].tap()
        app.buttons["No milestone"].tap()
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["Kept observation"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["journal.milestoneLabel"].exists)
    }
}
