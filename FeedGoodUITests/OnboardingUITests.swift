import XCTest

final class OnboardingUITests: XCTestCase {
    private func launchFreshOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING", "FEEDGOOD_ONBOARDING_RESET"]
        app.launch()
        XCTAssertTrue(app.staticTexts["onboarding.title.0"].waitForExistence(timeout: 5))
        return app
    }

    func testSkipFromWelcomeEntersTheApp() {
        let app = launchFreshOnboarding()
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testSkipFromHowItWorksEntersTheApp() {
        let app = launchFreshOnboarding()
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.title.1"].waitForExistence(timeout: 5))
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testSkipFromGetStartedEntersTheApp() {
        let app = launchFreshOnboarding()
        app.buttons["onboarding.continue"].tap()
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.title.2"].waitForExistence(timeout: 5))
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testExploreFirstEntersTheAppWithoutAddingAPlant() {
        let app = launchFreshOnboarding()
        app.buttons["onboarding.continue"].tap()
        app.buttons["onboarding.continue"].tap()
        app.buttons["onboarding.exploreFirst"].tap()

        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["plants.name"].exists == false)
    }

    func testAddFirstPlantOpensTheExistingAddPlantFlow() {
        let app = launchFreshOnboarding()
        app.buttons["onboarding.continue"].tap()
        app.buttons["onboarding.continue"].tap()
        app.buttons["onboarding.addFirstPlant"].tap()

        XCTAssertTrue(app.textFields["plants.name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["plants.save"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }
}
