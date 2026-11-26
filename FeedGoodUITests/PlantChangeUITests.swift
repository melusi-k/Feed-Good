import XCTest

final class PlantChangeUITests: XCTestCase {
    func testRecordEditAndDeleteAPlantChangeFromTheStory() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Change fern")
        app.buttons["plants.save"].tap()
        let row = app.descendants(matching: .any)["plants.row.Change fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["plantDetail.journal"].tap()
        app.buttons["journal.story"].tap()
        // Record a plant change through the journal editor's entry type.
        app.buttons["story.add"].tap()
        let typePicker = app.buttons["journal.entryType"]
        XCTAssertTrue(typePicker.waitForExistence(timeout: 5)); typePicker.tap()
        let plantChangeOption = app.buttons["Plant change"]
        XCTAssertTrue(plantChangeOption.waitForExistence(timeout: 5)); plantChangeOption.tap()
        let kindPicker = app.buttons["journal.changeKind"]
        XCTAssertTrue(kindPicker.waitForExistence(timeout: 5)); kindPicker.tap()
        let repottedOption = app.buttons["Repotted"]
        XCTAssertTrue(repottedOption.waitForExistence(timeout: 5)); repottedOption.tap()
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["Plant change: Repotted"].waitForExistence(timeout: 5))
        // Edit the same record into a different change kind; the note field stays untouched.
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "story.edit.")).firstMatch.tap()
        let editKind = app.buttons["journal.changeKind"]
        XCTAssertTrue(editKind.waitForExistence(timeout: 5)); editKind.tap()
        let growLightOption = app.buttons["Grow light started"]
        XCTAssertTrue(growLightOption.waitForExistence(timeout: 5)); growLightOption.tap()
        app.buttons["journal.save"].tap()
        XCTAssertTrue(app.staticTexts["Plant change: Grow light started"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Plant change: Repotted"].exists)
        // Delete the record from the journal; the story returns to empty and nothing else is affected.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.delete.")).firstMatch.tap()
        let confirm = app.buttons["Delete entry"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5)); confirm.tap()
        app.buttons["journal.story"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["story.empty"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Plant change: Grow light started"].exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Plant change record lifecycle"
        image.lifetime = .keepAlways; add(image)
    }
}
