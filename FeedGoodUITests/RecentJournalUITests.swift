import XCTest

final class RecentJournalUITests: XCTestCase {
    func testTodayUsesRealEntryAndRoutesToItsPlantJournal() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        func reveal(_ element: XCUIElement) {
            for _ in 0..<8 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable)
        }
        let empty = app.buttons["today.journal.empty"]
        reveal(empty)
        XCTAssertTrue(empty.exists)
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Moment fern")
        app.buttons["plants.save"].tap()
        app.tabBars.buttons["Journal"].tap()
        app.buttons["journal.add"].tap()
        let note = app.descendants(matching: .any)["journal.note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("An observation from my journal")
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["An observation from my journal"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Today"].tap()
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "today.journal.entry.")).firstMatch
        reveal(card)
        XCTAssertFalse(app.buttons["today.journal.empty"].exists)
        XCTAssertTrue(app.staticTexts["Recent journal moments"].exists)
        XCTAssertTrue(card.label.contains("Moment fern"))
        XCTAssertTrue(card.label.contains("An observation from my journal"))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Today real recent journal moment"
        image.lifetime = .keepAlways; add(image)
        card.tap()
        XCTAssertTrue(app.navigationBars["Plant journal"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["An observation from my journal"].exists)
        XCTAssertTrue(app.buttons["journal.story"].exists)
    }
}
