//
//  ConflictResolutionUITestCases.swift
//  GoInfoGameUITests
//
//  ConflictResolutionSheet (GoInfoGame/UI/Map/MapView.swift), shown when a quest
//  submission's changeset UPLOAD step comes back with a real 409 - the server's own
//  tags moved since the freshness fetch, on a key the user also just answered
//  differently (DatasyncManager.updateWay2/updateNode2's own conflict-detection path,
//  not a dedicated UI trigger). Each conflicting tag defaults to "Your answer"
//  (ConflictResolutionSheet.init seeds every choice as .useMine) - Confirm with no
//  changes keeps the user's own answers; Cancel leaves the element unsynced entirely
//  (DatasyncManager.syncWay's own catch for SyncConflictError.cancelledByUser).
//
//  Fixture: element 121949 (LongFormOSMElements.json) already has a freshness-fetch
//  override - ext:surface=asphalt, width=36 (LongFormLatestElements.json) - so its form
//  opens with "asphalt" prefilled. Answering "concrete" instead, then having the
//  (unchanged) "latest" fetch during conflict-handling still say "asphalt", is exactly
//  what produces a genuine one-tag conflict on ext:surface - not a fabricated UI state.
//

import XCTest

final class ConflictResolutionUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            usleep(300_000)
        } while Date() < deadline
        return condition()
    }

    private func findQuestAnnotation(_ app: XCUIApplication, elementID: Int64) -> XCUIElement? {
        app.buttons.matching(identifier: A11yID.Map.questAnnotation)
            .allElementsBoundByIndex.first(where: { $0.value as? String == "\(elementID)" })
    }

    @discardableResult
    private func openForm(_ app: XCUIApplication, elementID: Int64, timeout: TimeInterval = 40) -> Bool {
        guard waitUntil(timeout: timeout, condition: { findQuestAnnotation(app, elementID: elementID) != nil }),
              let pin = findQuestAnnotation(app, elementID: elementID) else { return false }
        pin.tap()
        return element(app, id: A11yID.LongForm.dismissButton).waitForExistence(timeout: 15)
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.LongForm.scrollView)
    }

    /// Mirrors LongFormScreenUITestCases' own copy of this helper (not visible across
    /// files) - see that file's own comment for why a plain swipe isn't enough here.
    @discardableResult
    private func scrollFormToElement(_ element: XCUIElement, in scrollView: XCUIElement, maxSwipes: Int = 16) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        let x: CGFloat = 15
        let topY = window.minY + 24
        let bottomY = window.maxY - 24
        func satisfied() -> Bool { element.isHittable }
        var swipes = 0
        while !satisfied() && swipes < maxSwipes {
            let down = !(element.exists && element.frame.midY < window.midY)
            // A full top-to-bottom swipe can jump a whole screen's worth of content in
            // one go - easily skipping clean over a short question sandwiched between two
            // taller ones before it's ever instantiated in this lazy CollectionView, after
            // which "scroll further down" can't recover since it never reverses direction
            // (see MultiQuestSelectionUITestCases' own copy of this fix for the full
            // writeup). A half-span swipe covers ground with much less overshoot risk.
            let half = (bottomY - topY) / 4
            let (fromY, toY) = down ? (window.midY + half, window.midY - half)
                                    : (window.midY - half, window.midY + half)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: fromY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: toY))
            start.press(forDuration: 0.05, thenDragTo: end)
            swipes += 1
        }
        return element.exists && satisfied()
    }

    private func dismissKeyboardIfShown(_ app: XCUIApplication) {
        let done = app.toolbars.buttons["Done"]
        if done.exists {
            done.tap()
            return
        }
        guard app.keyboards.count > 0 else { return }
        let list = scroll(in: app)
        let y = list.frame.minY + 24
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 15, dy: y))
            .tap()
    }

    /// Fills element 121949's form with an answer set that genuinely conflicts:
    /// "concrete" for surface (prefilled "asphalt"), plus every other applicable
    /// Sidewalks question so Submit enables. Leaves the sheet open on Submit.
    private func fillConflictingAnswerAndSubmit(_ app: XCUIApplication) {
        let scrollView = scroll(in: app)

        // Order matches the form's actual top-to-bottom layout, per
        // WorkspaceDetailsWithQuests.json's own quest array order: 107, 106, 101, 104
        // (102/105 are the OTHER component type's own entry, not shown here) -
        // scrollFormToElement's "nonexistent element means scroll further down"
        // heuristic can't recover from jumping back UP to an earlier question once
        // scrolled past it.
        let textEntry = element(app, id: A11yID.LongForm.textInput(questID: 107))
        XCTAssertTrue(scrollFormToElement(textEntry, in: scrollView), "Quest 107 text entry not reachable")
        textEntry.tap()
        textEntry.typeText("Conflict test")
        dismissKeyboardIfShown(app)

        let choice1 = element(app, id: A11yID.LongForm.option(questID: 106, value: "choice_1"))
        XCTAssertTrue(scrollFormToElement(choice1, in: scrollView), "Quest 106 choice_1 not reachable")
        choice1.tap()

        let concrete = element(app, id: A11yID.LongForm.option(questID: 101, value: "concrete"))
        XCTAssertTrue(scrollFormToElement(concrete, in: scrollView), "Surface option not reachable")
        concrete.tap()

        let obstructionNo = element(app, id: A11yID.LongForm.option(questID: 104, value: "no"))
        XCTAssertTrue(scrollFormToElement(obstructionNo, in: scrollView), "Obstruction option not reachable")
        obstructionNo.tap()

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Submit disabled despite every applicable question being answered")
        submit.tap()
    }

    // MARK: - Tests

    func testConflictSheetAppearsAndConfirmingKeepsMyAnswer() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormConflict)
        XCTAssertTrue(openForm(app, elementID: 121949), "Form did not open")
        fillConflictingAnswerAndSubmit(app)

        let confirmButton = element(app, id: A11yID.ConflictResolution.confirmButton)
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 15), "Conflict resolution sheet did not appear")
        XCTAssertTrue(element(app, id: A11yID.ConflictResolution.useMineChoice(tagKey: "ext:surface")).exists,
                      "No conflict row for ext:surface - the expected conflicting tag")

        // Defaults to "Your answer" for every tag (ConflictResolutionSheet.init) -
        // confirming with no changes keeps "concrete", the user's own answer.
        confirmButton.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Did not return to the Map screen after confirming the conflict resolution")
        XCTAssertTrue(waitUntil(timeout: 30, condition: { findQuestAnnotation(app, elementID: 121949) == nil }),
                      "Element 121949's pin is still on the map after resolving the conflict and retrying")
    }

    func testCancellingConflictLeavesElementUnsyncedWithPinStillPresent() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormConflict)
        XCTAssertTrue(openForm(app, elementID: 121949), "Form did not open")
        fillConflictingAnswerAndSubmit(app)

        let cancelButton = element(app, id: A11yID.ConflictResolution.cancelButton)
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 15), "Conflict resolution sheet did not appear")
        cancelButton.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after cancelling the conflict resolution")
        // Give the (declined) sync attempt a moment to actually finish before checking -
        // same reasoning as this project's other "prove nothing happened" assertions.
        sleep(3)
        XCTAssertTrue(findQuestAnnotation(app, elementID: 121949) != nil,
                      "Element 121949's pin disappeared despite the conflict being cancelled, not resolved")
    }

    func testConflictSheetLayout() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormConflict)
        XCTAssertTrue(openForm(app, elementID: 121949), "Form did not open")
        fillConflictingAnswerAndSubmit(app)

        let cancelButton = element(app, id: A11yID.ConflictResolution.cancelButton)
        let confirmButton = element(app, id: A11yID.ConflictResolution.confirmButton)
        let choiceRow = element(app, id: A11yID.ConflictResolution.useMineChoice(tagKey: "ext:surface"))
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 15), "Conflict resolution sheet did not appear")

        let window = app.windows.firstMatch.frame
        for (name, control) in [("Cancel button", cancelButton), ("Confirm button", confirmButton), ("Use-mine choice row", choiceRow)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
        }
        assertNoOverlap([(cancelButton, "Cancel button"), (confirmButton, "Confirm button")])
    }
}
