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
        let emptyImage = XCTAttachment(screenshot: app.screenshot())
        emptyImage.name = "SIMULATOR - My Plants no matching plants and clear search"
        emptyImage.lifetime = .keepAlways; add(emptyImage)
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
    func testArchivePreservesStoryAndRestoreReturnsSamePlantToActiveCollection() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Archive fern")
        app.buttons["plants.save"].tap()

        let activeRow = app.buttons["plants.row.Archive fern"]
        XCTAssertTrue(activeRow.waitForExistence(timeout: 5))
        activeRow.tap()
        // Wait for the pushed detail screen before interacting with its actions.
        let archiveButton = app.buttons["plantDetail.archive"]
        XCTAssertTrue(archiveButton.waitForExistence(timeout: 10), "Selecting the plant should open its detail screen.")
        archiveButton.tap()
        // iOS 26 mirrors confirmation-dialog buttons in the accessibility
        // tree, so the one Archive button matches twice; tap the first.
        let archiveConfirmation = app.buttons.matching(identifier: "plantDetail.archive.confirm").firstMatch
        XCTAssertTrue(archiveConfirmation.waitForExistence(timeout: 5))
        archiveConfirmation.tap()

        XCTAssertTrue(app.descendants(matching: .any)["plantDetail.archivedStatus"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["plantDetail.care"].exists)
        XCTAssertFalse(app.buttons["plantDetail.routineReview"].exists)
        XCTAssertTrue(app.buttons["plantDetail.journal"].exists)
        app.buttons["plantDetail.journal"].tap()
        app.buttons["journal.story"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["story.archivedStatus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["story.empty"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["plants.archived"].tap()
        let archivedRow = app.buttons["plants.archived.row.Archive fern"]
        XCTAssertTrue(archivedRow.waitForExistence(timeout: 5))
        archivedRow.tap()
        XCTAssertTrue(app.descendants(matching: .any)["plantDetail.archivedStatus"].waitForExistence(timeout: 5))
        app.buttons["plantDetail.restore"].tap()
        // Same iOS 26 dialog mirroring as the archive confirmation above.
        let restoreConfirmation = app.buttons.matching(identifier: "plantDetail.restore.confirm").firstMatch
        XCTAssertTrue(restoreConfirmation.waitForExistence(timeout: 5))
        restoreConfirmation.tap()

        XCTAssertTrue(app.descendants(matching: .any)["plantDetail.archivedStatus"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["plantDetail.care"].exists)
        XCTAssertTrue(app.buttons["plantDetail.routineReview"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["plants.archived.row.Archive fern"].waitForNonExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["plants.row.Archive fern"].waitForExistence(timeout: 5))
    }

}
