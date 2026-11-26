import XCTest

final class QuietPeriodUITests: XCTestCase {
    func testCreateAndEndOpenEndedQuietPeriodWithoutBlockingJournal() {
        let app = XCUIApplication()
        app.launchArguments = ["FEEDGOOD_UI_TESTING"]
        app.launch()
        app.tabBars.buttons["My Plants"].tap()

        app.buttons["plants.add"].tap()
        let name = app.textFields["plants.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Quiet fern")
        app.buttons["plants.save"].tap()

        let row = app.descendants(matching: .any)["plants.row.Quiet fern"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        app.buttons["plantDetail.care"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))
        app.buttons["care.add"].tap()
        app.buttons["care.taskSave"].tap()
        let savePreview = app.alerts["Review care changes"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 5))
        savePreview.buttons["Save changes"].tap()
        XCTAssertTrue(app.buttons["care.add"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let quietPeriodLink = app.buttons["plantDetail.quietPeriod"]
        XCTAssertTrue(quietPeriodLink.waitForExistence(timeout: 5))
        quietPeriodLink.tap()

        let impactPreview = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "remaining time on each selected task is frozen")
        ).firstMatch
        XCTAssertTrue(impactPreview.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quietPeriod.confirm"].waitForExistence(timeout: 5))
        app.buttons["quietPeriod.confirm"].tap()

        // Creation saves and dismisses back to the plant profile.
        XCTAssertTrue(app.buttons["plantDetail.quietPeriod"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["plantDetail.quietPeriod"].label, "Manage Quiet Period")

        // A Quiet Period must not block the plant journal.
        app.buttons["plantDetail.journal"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // The active period leaves the journal available from the plant profile.
        XCTAssertTrue(app.buttons["plantDetail.journal"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Active Quiet Period with journal available"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Reopen management only after the profile link is actually hittable.
        // A visible accessibility element can still be in a navigation transition;
        // tapping it too early can be swallowed and leave the test on the profile.
        let manageQuietPeriod = app.buttons["plantDetail.quietPeriod"]
        XCTAssertTrue(manageQuietPeriod.waitForExistence(timeout: 5))
        // Lazy Form rows can exist without a valid frame until scrolled into
        // view; scroll to reveal the link before waiting for hittability.
        for _ in 0..<3 where !manageQuietPeriod.isHittable { app.swipeUp() }
        let manageLinkHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: manageQuietPeriod
        )
        guard XCTWaiter.wait(for: [manageLinkHittable], timeout: 5) == .completed else {
            XCTFail("Quiet Period management link never became hittable after returning to the plant profile.")
            return
        }
        manageQuietPeriod.tap()
        let endButton = app.buttons["quietPeriod.end"]
        guard endButton.waitForExistence(timeout: 5) else {
            XCTFail("Tapping the Quiet Period management link did not open the active-period controls.")
            return
        }
        app.buttons["quietPeriod.edit"].tap()
        let reason = app.textFields["quietPeriod.editReason"]
        XCTAssertTrue(reason.waitForExistence(timeout: 5))
        reason.tap()
        reason.typeText("Winter break")
        app.buttons["quietPeriod.saveEdit"].tap()
        XCTAssertTrue(app.buttons["quietPeriod.edit"].waitForExistence(timeout: 5))
        app.buttons["quietPeriod.end"].tap()
        XCTAssertTrue(app.buttons["plantDetail.care"].waitForExistence(timeout: 5))

    }
}
