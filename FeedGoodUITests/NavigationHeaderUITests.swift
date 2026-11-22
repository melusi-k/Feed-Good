import XCTest

final class NavigationHeaderUITests: XCTestCase {
    private func header(_ app: XCUIApplication, _ title: String) {
        let label = app.navigationBars.staticTexts.matching(NSPredicate(format: "identifier == %@ AND label == %@", "app.header.title", title)).firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertEqual(label.label, title)
        XCTAssertTrue(label.isHittable)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - Shared header - \(name)"
        image.lifetime = .keepAlways
        add(image)
    }

    func testHorizontalTabSwipesKeepNativeNavigationAndScrolling() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        header(app, "Feed Good")
        let middle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.3))
        middle.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.3)))
        header(app, "My Plants")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.3)).press(forDuration: 0.1, thenDragTo: middle)
        header(app, "Feed Good")
        app.swipeUp()
        header(app, "Feed Good")
        capture(app, "Tab swipe and vertical scroll")
    }

    func testRootHeadersStayVisibleAfterScrollAndInDarkAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        header(app, "Feed Good")
        app.swipeUp()
        app.swipeUp()
        header(app, "Feed Good")
        capture(app, "Today after scrolling")
        for tab in ["My Plants", "Journal", "Settings"] {
            app.tabBars.buttons[tab].tap()
            header(app, tab)
            app.swipeUp()
            header(app, tab)
            capture(app, "\(tab) after scrolling")
        }
        app.swipeDown()
        app.buttons["Dark"].tap()
        header(app, "Settings")
        capture(app, "Settings dark")
        app.buttons["System"].tap()
    }

    func testHeadersOnSheetPushEditCareAndJournalRoutes() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        header(app, "New plant")
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Header fern")
        app.buttons["plants.save"].tap()
        app.buttons["plants.row.Header fern"].tap()
        header(app, "Header fern")
        app.swipeUp()
        header(app, "Header fern")
        capture(app, "Plant detail after scrolling")
        app.tabBars.buttons["Journal"].tap()
        header(app, "Journal")
        app.tabBars.buttons["My Plants"].tap()
        header(app, "Header fern") // Switching tabs preserves the detail path.
        app.buttons["plantDetail.edit"].tap()
        header(app, "Edit plant")
        app.buttons["Cancel"].tap()
        header(app, "Header fern")
        app.swipeDown()
        app.buttons["plantDetail.care"].tap()
        header(app, "Care routine")
        app.buttons["care.add"].tap()
        header(app, "Add care task")
        app.buttons["Cancel"].tap()
        header(app, "Care routine")
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        header(app, "Header fern")
        capture(app, "Returned from care with native swipe back")
        app.tabBars.buttons["Journal"].tap()
        header(app, "Journal")
        app.buttons["journal.add"].tap()
        header(app, "New journal entry")
        capture(app, "Journal editor with native actions")
        app.buttons["Cancel"].tap()
        header(app, "Journal")
    }
}
