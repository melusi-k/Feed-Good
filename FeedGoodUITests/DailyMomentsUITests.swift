import XCTest

final class DailyMomentsUITests: XCTestCase {
    func testBundledDailyContentAndSourceReviewAreVisible() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        let reflection = app.staticTexts["today.dailyThought"]
        XCTAssertTrue(reflection.waitForExistence(timeout: 5))
        let reflectionText = reflection.label
        XCTAssertFalse(reflectionText.isEmpty)
        XCTAssertTrue(app.staticTexts["A reflection, not a care instruction."].exists)
        let top = XCTAttachment(screenshot: app.screenshot())
        top.name = "SIMULATOR - Today bundled daily reflection"
        top.lifetime = .keepAlways
        add(top)

        let source = app.buttons["today.tipSource"]
        for _ in 0..<3 where !source.isHittable { app.swipeUp() }
        XCTAssertTrue(source.isHittable)
        let tip = app.staticTexts["today.careTip"]
        XCTAssertTrue(tip.exists)
        XCTAssertFalse(tip.label.isEmpty)
        XCTAssertNotEqual(tip.label, reflectionText)
        XCTAssertTrue(app.staticTexts["General houseplant education. Check your plant's own needs."].exists)
        let card = XCTAttachment(screenshot: app.screenshot())
        card.name = "SIMULATOR - Today bundled general care tip"
        card.lifetime = .keepAlways
        add(card)
        source.tap()
        XCTAssertTrue(app.staticTexts["today.sourceTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["today.reviewStatus"].label, "Source checked, not expert reviewed")
        let review = XCTAttachment(screenshot: app.screenshot())
        review.name = "SIMULATOR - Daily tip source and honest review status"
        review.lifetime = .keepAlways
        add(review)
        app.buttons["today.sourceDone"].tap()
        XCTAssertFalse(app.staticTexts["today.reviewStatus"].exists)
    }
}
