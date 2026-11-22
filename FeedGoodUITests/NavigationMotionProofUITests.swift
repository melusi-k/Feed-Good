import XCTest

/// Real-time evidence only. No app animation timing or product flags are changed.
final class NavigationMotionProofUITests: XCTestCase {
    private func mark(_ name: String) {
        print("MOTION_PROOF \(Date().timeIntervalSince1970) \(name)")
        Thread.sleep(forTimeInterval: 0.7) // Separate actions for the recording viewer.
    }

    private func header(_ app: XCUIApplication, _ title: String) {
        let value = app.navigationBars.staticTexts.matching(NSPredicate(format: "identifier == %@ AND label == %@", "app.header.title", title)).firstMatch
        XCTAssertTrue(value.waitForExistence(timeout: 5))
        XCTAssertTrue(value.isHittable)
    }

    func testRecordedTabTapSwipeDetailReturnAndHeldButton() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        header(app, "Feed Good")
        mark("TAB_TAP_TODAY_TO_PLANTS")
        app.tabBars.buttons["My Plants"].tap()
        header(app, "My Plants")
        mark("TAB_TAP_PLANTS_TO_JOURNAL")
        app.tabBars.buttons["Journal"].tap()
        header(app, "Journal")
        mark("TAB_SWIPE_JOURNAL_TO_PLANTS")
        let left = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.3))
        let right = app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.3))
        left.press(forDuration: 0.1, thenDragTo: right)
        header(app, "My Plants")
        mark("TAB_SWIPE_PLANTS_TO_JOURNAL")
        right.press(forDuration: 0.1, thenDragTo: left)
        header(app, "Journal")
        app.tabBars.buttons["My Plants"].tap()
        header(app, "My Plants")
        mark("HELD_PROMINENT_ADD_BUTTON")
        app.buttons["Add a plant"].press(forDuration: 1.2)
        header(app, "New plant")
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Motion fern")
        app.buttons["plants.save"].tap()
        let plant = app.buttons["plants.row.Motion fern"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        mark("CLICK_OPEN_PLANT_DETAIL")
        plant.tap()
        header(app, "Motion fern")
        mark("HELD_CARE_LINK_AND_PUSH")
        app.buttons["plantDetail.care"].press(forDuration: 1.2)
        header(app, "Care routine")
        mark("EDGE_SWIPE_RETURN_TO_PLANT_DETAIL")
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        header(app, "Motion fern")
        mark("CLICK_BACK_FROM_PLANT_DETAIL")
        app.navigationBars.buttons["My Plants"].tap()
        header(app, "My Plants")
        mark("PROOF_COMPLETE")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "SIMULATOR (CI) - Motion proof completed"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
