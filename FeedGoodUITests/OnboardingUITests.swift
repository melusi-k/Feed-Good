import XCTest

final class OnboardingUITests: XCTestCase {
    func testFreshLaunchShowsFlowAndExploreFirstDismisses() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_ONBOARDING_RESET"]
        app.launch()

        XCTAssertTrue(app.staticTexts["onboarding.welcome.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.skip"].exists)

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.howItWorks.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.skip"].exists)

        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.getStarted.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No account needed."].exists)

        app.buttons["onboarding.exploreFirst"].tap()
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))

        // Relaunch with a clean argument list: onboarding stays away.
        let relaunched = XCUIApplication()
        relaunched.launch()
        XCTAssertTrue(relaunched.staticTexts["onboarding.welcome.title"].waitForExistence(timeout: 2) == false)
        XCTAssertTrue(relaunched.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testSkipDismissesFromTheFirstPage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_ONBOARDING_RESET"]
        app.launch()

        XCTAssertTrue(app.staticTexts["onboarding.welcome.title"].waitForExistence(timeout: 5))
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.staticTexts["today.welcome"].waitForExistence(timeout: 5))
    }

    func testAddYourFirstPlantOpensAddPlant() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_ONBOARDING_RESET"]
        app.launch()

        XCTAssertTrue(app.staticTexts["onboarding.welcome.title"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.howItWorks.title"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.getStarted.title"].waitForExistence(timeout: 5))

        app.buttons["onboarding.addFirstPlant"].tap()
        let nameField = app.textFields["plants.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    }
}
