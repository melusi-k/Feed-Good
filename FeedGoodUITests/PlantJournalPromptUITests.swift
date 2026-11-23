import XCTest

final class PlantJournalPromptUITests: XCTestCase {
    private func makePlant(_ app: XCUIApplication, _ name: String) {
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let field = app.textFields["plants.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(name)
        app.buttons["plants.save"].tap()
    }

    private func openStory(_ app: XCUIApplication, _ name: String) {
        app.tabBars.buttons["My Plants"].tap()
        let row = app.descendants(matching: .any)["plants.row.\(name)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["plantDetail.journal"].tap()
        app.buttons["journal.story"].tap()
    }

    func testAnswerPromptCreatesOrdinaryJournalEntryAndHidesCard() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        makePlant(app, "Prompt fern")
        openStory(app, "Prompt fern")
        let card = app.descendants(matching: .any)["journalPrompt.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["An optional idea, never a task."].exists)
        app.buttons["journalPrompt.answer"].tap()
        let note = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("Two new fronds uncurling")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["Two new fronds uncurling"].waitForExistence(timeout: 5))
        // Answering hides the card for the rest of the day: no obligation remains.
        XCTAssertFalse(app.descendants(matching: .any)["journalPrompt.card"].exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Answered journal prompt"
        image.lifetime = .keepAlways; add(image)
    }

    func testSkipPromptHidesCardWithoutPenalty() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        makePlant(app, "Skip fern")
        openStory(app, "Skip fern")
        let card = app.descendants(matching: .any)["journalPrompt.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        app.buttons["journalPrompt.notNow"].tap()
        let skip = app.buttons["journalPrompt.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5)); skip.tap()
        XCTAssertFalse(app.descendants(matching: .any)["journalPrompt.card"].exists)
        // The story still works normally: adding an observation is unaffected.
        app.buttons["story.add"].tap()
        let note = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("Checked the soil today")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["Checked the soil today"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["journalPrompt.card"].exists)
    }
}
