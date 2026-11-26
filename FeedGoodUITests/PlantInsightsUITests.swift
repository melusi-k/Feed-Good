import XCTest

final class PlantInsightsUITests: XCTestCase {
    func testPlantProfileOpensInsightsWithEvidenceGapState() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Insights calathea")
        app.buttons["plants.save"].tap()

        let plantRow = app.descendants(matching: .any)["plants.row.Insights calathea"]
        XCTAssertTrue(plantRow.waitForExistence(timeout: 5))
        plantRow.tap()

        let insightsLink = app.buttons["plantDetail.insights"]
        XCTAssertTrue(insightsLink.waitForExistence(timeout: 5))
        insightsLink.tap()

        // A plant with no journal records shows the honest evidence gap,
        // never a manufactured trend.
        XCTAssertTrue(app.staticTexts["Not enough records yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[
            "Journal entries, milestones and photos you record for this plant will appear here."
        ].exists)
    }
}
