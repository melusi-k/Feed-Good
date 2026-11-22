import XCTest

final class GrowthReviewUITests: XCTestCase {
    func testEmptyGrowthReviewPointsToAddObservation() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()
        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Growth fern")
        app.buttons["plants.save"].tap()
        let row = app.descendants(matching: .any)["plants.row.Growth fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        let growth = app.buttons["plantDetail.growth"]
        XCTAssertTrue(growth.waitForExistence(timeout: 5)); growth.tap()
        XCTAssertTrue(app.descendants(matching: .any)["growthReview.empty"].waitForExistence(timeout: 5))
        app.buttons["growthReview.emptyAdd"].tap()
        XCTAssertTrue(app.buttons["journal.save"].waitForExistence(timeout: 5))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Growth review empty state points to Add observation"
        image.lifetime = .keepAlways; add(image)
    }
}
