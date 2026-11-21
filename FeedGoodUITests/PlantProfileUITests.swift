import XCTest

final class PlantProfileUITests: XCTestCase {
    /// Journeys run against an in-memory store (see FeedGoodApp) so they are
    /// deterministic and leave the simulator's on-device garden untouched.
    func testAddOpenEditAndDeletePlantProfile() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()

        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let nameField = app.textFields["plants.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Monstera")
        app.buttons["plants.save"].tap()

        let row = app.descendants(matching: .any)["plants.row.Monstera"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.staticTexts["plantDetail.name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Species not added yet"].exists)

        app.buttons["plantDetail.edit"].tap()
        let editName = app.textFields["editPlant.name"]
        XCTAssertTrue(editName.waitForExistence(timeout: 5))
        editName.tap()
        let existingValue = editName.value as? String ?? ""
        editName.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        editName.typeText("Monty")
        app.buttons["editPlant.save"].tap()

        XCTAssertTrue(app.staticTexts["Monty"].waitForExistence(timeout: 5))

        app.buttons["plantDetail.delete"].tap()
        let confirmButton = app.alerts.firstMatch.buttons["Delete"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertTrue(app.staticTexts["Your garden starts here"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["plants.row.Monstera"].exists)
    }
}
