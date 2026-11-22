import XCTest

final class ProfileUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "SIMULATOR - Profile - \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEveryRootOpensTheSameProfileAndDonePreservesSelectedTab() {
        let app = launch()
        for tab in ["Today", "My Plants", "Journal", "Settings"] {
            app.tabBars.buttons[tab].tap()
            let button = app.buttons["profile.open"]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            XCTAssertTrue(button.isHittable)
            capture(app, "\(tab) entry")
            button.tap()
            XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Your garden"].exists)
            XCTAssertEqual(app.descendants(matching: .any)["profile.stats.plants"].label, "0 Plants")
            XCTAssertEqual(app.descendants(matching: .any)["profile.stats.care"].label, "0 Care records")
            XCTAssertEqual(app.descendants(matching: .any)["profile.stats.journal"].label, "0 Journal entries")
            if tab == "Today" { capture(app, "Shared sheet light") }
            app.buttons["profile.done"].tap()
            XCTAssertTrue(app.tabBars.buttons[tab].isSelected)
        }
        XCTAssertTrue(app.buttons["Dark"].exists)
    }

    func testSavedPlantAppearsInProfileAndIconStaysOffPushedPages() {
        let app = launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()

        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Profile fern")

        let species = app.textFields["plants.species"]
        XCTAssertTrue(species.exists)
        species.tap()
        species.typeText("Nephrolepis exaltata")

        let notes = app.textViews["plants.notes"]
        XCTAssertTrue(notes.exists)
        notes.tap()
        notes.typeText("Bright indirect light; keep soil lightly moist.")

        app.buttons["plants.save"].tap()
        app.buttons["profile.open"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["profile.stats.plants"].label, "1 Plants")
        XCTAssertEqual(app.descendants(matching: .any)["profile.stats.care"].label, "0 Care records")
        XCTAssertEqual(app.descendants(matching: .any)["profile.stats.journal"].label, "0 Journal entries")
        capture(app, "Populated sheet")

        app.buttons["profile.context"].tap()
        XCTAssertTrue(app.staticTexts["Profile fern"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nephrolepis exaltata"].exists)
        XCTAssertTrue(app.staticTexts["Bright indirect light; keep soil lightly moist."].exists)
        app.navigationBars["Growing context"].buttons["Profile"].tap()
        app.buttons["profile.done"].tap()
        app.buttons["plants.row.Profile fern"].tap()
        XCTAssertTrue(app.navigationBars["Profile fern"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["profile.open"].exists)
    }

    func testSwipeDismissAndSettingsRouteAndDarkAppearance() {
        let app = launch()
        app.buttons["profile.open"].tap()
        let navigationBar = app.navigationBars["Profile"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        navigationBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
        let dismissal = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: navigationBar)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissal], timeout: 5), .completed)
        app.buttons["profile.open"].tap()
        app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
        app.buttons["Dark"].tap()
        app.buttons["profile.open"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        capture(app, "Shared sheet dark")
        app.buttons["profile.done"].tap()
        app.buttons["System"].tap()
    }
}
