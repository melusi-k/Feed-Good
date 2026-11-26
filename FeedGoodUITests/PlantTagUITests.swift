import XCTest

final class PlantTagUITests: XCTestCase {
    private func makePlant(_ app: XCUIApplication, _ name: String) {
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let field = app.textFields["plants.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(name)
        app.buttons["plants.save"].tap()
    }

    private func assignTag(_ app: XCUIApplication, plant: String, tag: String) {
        app.tabBars.buttons["My Plants"].tap()
        let row = app.descendants(matching: .any)["plants.row.\(plant)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        let edit = app.buttons["plantDetail.edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5)); edit.tap()
        let field = app.textFields["editPlant.newTag"]
        // iOS 26 materializes lazy Form rows only once they scroll into view,
        // so scroll the Tags section on screen before expecting the field.
        var scrolls = 0
        while field.exists == false, scrolls < 8 { app.swipeUp(); scrolls += 1 }
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // The Tags section closes a long form, so the field can still start
        // clipped at the bottom edge: XCTest still reports it hittable while
        // its centre sits off-screen, and a tap there cannot take keyboard
        // focus. Scroll until the whole field is on screen, as a user would.
        if field.exists {
            while field.frame.maxY > app.frame.height - 8, scrolls < 8 { app.swipeUp(); scrolls += 1 }
            XCTAssertTrue(field.frame.maxY <= app.frame.height - 8)
        }
        field.tap(); field.typeText(tag)
        app.buttons["editPlant.addTag"].tap()
        app.buttons["editPlant.save"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }

    func testAssignFilterAndClearTags() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        makePlant(app, "Tag fern")
        makePlant(app, "Tag aloe")
        assignTag(app, plant: "Tag fern", tag: "Shade")
        // The chip row appears with the new tag and the row lists it.
        let chip = app.buttons["plants.tagFilter.Shade"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["plants.tags.Tag fern"].exists)
        // Filtering shows only tagged plants; the untagged one disappears.
        chip.tap()
        XCTAssertTrue(app.descendants(matching: .any)["plants.row.Tag fern"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["plants.row.Tag aloe"].waitForNonExistence(timeout: 5))
        // Clear returns the full collection.
        let clear = app.buttons["plants.tagFilter.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5)); clear.tap()
        XCTAssertTrue(app.descendants(matching: .any)["plants.row.Tag aloe"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["plants.row.Tag fern"].exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Tag filter and clear"
        image.lifetime = .keepAlways; add(image)
    }

    func testTagCreationStaysOptionalAndCollectionWorksWithoutTags() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        makePlant(app, "Plain fern")
        // No tags exist: no chip row, collection fully usable.
        XCTAssertFalse(app.descendants(matching: .any)["plants.tagFilter"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["plants.row.Plain fern"].exists)
    }
}
