import XCTest

final class TodayScreenUITests: XCTestCase {
    func testTodayScreenIntroducesTheGardenAndOffersAFirstStep() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["today.dailyThought"].exists)
        XCTAssertTrue(app.buttons["today.careCheckIn.action"].exists)
        XCTAssertTrue(app.staticTexts["Make room for a little green"].exists)
    }

    func testCareCompleteButtonShowsItsLabelInLightAndDark() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()

        // Seed a plant with a watering routine so Today offers a Done action.
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Done fern")
        app.buttons["plants.save"].tap()
        let row = app.descendants(matching: .any)["plants.row.Done fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["plantDetail.care"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let savePreview = app.alerts["Review care changes"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 5))
        savePreview.buttons["Save changes"].tap()

        // The Done control is exposed as the row's merged accessibility
        // element (row identifier + the button's Record label).
        let done = app.buttons["today.care.row.Done fern.Watering"]
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        XCTAssertEqual(done.label, "Record Watering for Done fern")
        XCTAssertGreaterThanOrEqual(done.frame.height, 44)
        let light = XCTAttachment(screenshot: app.screenshot())
        light.name = "SIMULATOR - Today Done button - light"
        light.lifetime = .keepAlways
        add(light)

        // The app has no in-app appearance toggle; force the system
        // appearance through XCTest's official hook instead.
        XCUIDevice.shared.appearance = .dark
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        XCTAssertEqual(done.label, "Record Watering for Done fern")
        let dark = XCTAttachment(screenshot: app.screenshot())
        dark.name = "SIMULATOR - Today Done button - dark"
        dark.lifetime = .keepAlways
        add(dark)

        XCUIDevice.shared.appearance = .unspecified
    }

    func testAppearanceCanBeChangedAndPersistsInSettings() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let appearancePicker = app.descendants(matching: .any)["settings.appearance"]
        XCTAssertTrue(appearancePicker.waitForExistence(timeout: 5))

        let darkOption = app.buttons["Dark"]
        XCTAssertTrue(darkOption.waitForExistence(timeout: 3))
        darkOption.tap()
        XCTAssertTrue(app.staticTexts["Dark appearance"].waitForExistence(timeout: 5))

        app.buttons["Light"].tap()
        XCTAssertTrue(app.staticTexts["Light appearance"].waitForExistence(timeout: 5))

        app.buttons["System"].tap()
        XCTAssertTrue(app.staticTexts["System appearance"].waitForExistence(timeout: 5))
    }
}
