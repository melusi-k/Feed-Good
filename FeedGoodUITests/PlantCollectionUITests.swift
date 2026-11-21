import XCTest

final class PlantCollectionUITests: XCTestCase {
    func testSearchEmptyRecoverySortAndCorrectPlantRoute() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        for plantName in ["Zulu fern", "Aloe desk"] {
            app.buttons["plants.add"].tap()
            let name = app.textFields["plants.name"]
            XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText(plantName)
            app.buttons["plants.save"].tap()
            XCTAssertTrue(app.buttons["plants.row.\(plantName)"].waitForExistence(timeout: 5))
        }
        app.buttons["plants.sort"].tap()
        app.buttons["Name"].tap()
        let aloe = app.buttons["plants.row.Aloe desk"]
        let fern = app.buttons["plants.row.Zulu fern"]
        XCTAssertLessThan(aloe.frame.minY, fern.frame.minY)
        let search = app.searchFields.firstMatch
        if !search.isHittable { app.swipeDown() }
        XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); search.typeText("FERN")
        XCTAssertTrue(fern.waitForExistence(timeout: 5))
        XCTAssertFalse(aloe.exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SIMULATOR - My Plants name search and sort"
        image.lifetime = .keepAlways; add(image)
        search.tap(); search.typeText(" no match")
        XCTAssertTrue(app.descendants(matching: .any)["plants.search.empty"].waitForExistence(timeout: 5))
        app.buttons["plants.search.clear"].tap()
        XCTAssertTrue(aloe.waitForExistence(timeout: 5))
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        fern.tap()
        XCTAssertEqual(app.staticTexts["plantDetail.name"].label, "Zulu fern")
    }

    func testSortSelectionPersistsAcrossLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.sort"].tap()
        app.buttons["Name"].tap()
        app.terminate(); app.launch()
        app.tabBars.buttons["My Plants"].tap()
        XCTAssertTrue(app.buttons["plants.sort"].label.contains("Name"))
        // Leave a known default for independent existing journeys.
        app.buttons["plants.sort"].tap()
        app.buttons["Recently added"].tap()
    }
}
