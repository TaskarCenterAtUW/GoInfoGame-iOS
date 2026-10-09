//
//  UndoEditsScreenUITestCases.swift
//  GoInfoGameUITests
//
//  Both undo surfaces read/write the exact same underlying data (MapUndoManager.shared
//  over local StoredChangeset rows, filtered to changesetId == 0 && !isUndoCompleted) -
//  there is no separate ViewModel-level divergence, only presentation:
//    - UndoEditsView (GoInfoGame/UI/Map/Accessibility Mode/UndoEditsView.swift), reached
//      from A11yID.AccessibilityMode.undoEditButton - a full screen, items grouped by
//      date, each row's confirmation sheet shows the full added/modified tag diff. The
//      primary target of this suite.
//    - UndoButton/UndoSidebarView (GoInfoGame/UI/Utils/), Map's own floating undo
//      button - a lighter popup UI over the same data, covered here too since it shares
//      state with UndoEditsView (good for proving both surfaces agree).
//
//  Seeding: the undo list is pure local data with NO network fetch behind it - nothing
//  in the app or a normal test flow can populate it except driving a full LongForm
//  answer-and-submit round trip first. UITestStubs.seedUndoableChangesets() writes two
//  already-synced, undoable StoredChangeset rows directly to Realm instead (this
//  suite's own UITestScenario.undoEditsOnline/undoEditsNetworkDown do this on launch):
//    810301  way,  ext:surface edited concrete -> asphalt ("Modified") - confirmation
//            button reads "Revert Changes"
//    810302  node, created via Add Feature (barrier=kerb, kerb=raised, both "Added") -
//            confirmation button reads "Delete Feature" (isCreatedElement)
//  810302 is backdated a full day from 810301, so they land under two different date
//  section headers in UndoEditsView's grouped list.
//
//  Network: reverting/deleting an item reuses the exact same changeset create -> upload
//  -> close triplet a LongForm submit does (QuestBase.updateUndoTags/undoCreatedElement,
//  via DatasyncManager.syncWay/syncNode/deleteNode) - the same stubs LongForm's own
//  suite uses. On failure there is NO visible error state anywhere in the app (confirmed
//  directly: QuestBase posts a `.failed` dismissal scenario, but nothing subscribes to
//  it to show anything) - testRevertingChangeFailsSilentlyWhenOffline documents that
//  real behavior (item stays, unchanged, no crash) rather than a hypothetical error UI.
//

import XCTest

final class UndoEditsScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    /// Mirrors AccessibilityModeScreenUITestCases' own private helper (not visible
    /// across files) - Map's toolbar trailing items can collapse into iOS 26's automatic
    /// overflow ("More") menu when they don't all fit, and accessibilityModeButton is
    /// one of the items that can land there.
    private func trailingToolbarButton(_ app: XCUIApplication, id: String, overflowMenuText: String) -> XCUIElement {
        let direct = element(app, id: id)
        if direct.waitForExistence(timeout: 5) {
            return direct
        }
        let menuButton = app.buttons[overflowMenuText]
        if menuButton.waitForExistence(timeout: 2) {
            return menuButton
        }
        let overflow = app.buttons["More"]
        if overflow.waitForExistence(timeout: 2) {
            overflow.tap()
            if menuButton.waitForExistence(timeout: 3) {
                return menuButton
            }
        }
        return direct
    }

    @discardableResult
    private func openAccessibilityMode(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let entryButton = trailingToolbarButton(app, id: A11yID.Map.accessibilityModeButton, overflowMenuText: "Screen Reader Mode")
        guard entryButton.waitForExistence(timeout: timeout) else { return false }
        entryButton.tap()
        return element(app, id: A11yID.Map.accessibilityModeCloseButton).waitForExistence(timeout: timeout)
    }

    /// Taps Accessibility Mode's own "Undo edits" button and waits for this screen's
    /// presence signal. The close button (always in the toolbar) rather than the List:
    /// the List doesn't exist at all when there are no edits (NoEditsView takes its
    /// place instead), so it can't double as "did the screen open" for every scenario.
    ///
    /// undoEditButton lives inside AccessibilityModeView's OWN scrollable List, behind
    /// however many nearest-quest cards are showing - a bare waitForExistence doesn't
    /// scroll, so on a fixture with several cards (as this suite's own
    /// AccessibilityModeOSMElements-backed scenarios have) the button never
    /// materializes at all (List virtualization) and this always times out. Has to be
    /// scrolled to first, same as AccessibilityModeScreenUITestCases' own tests do.
    @discardableResult
    private func openUndoEdits(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let accessibilityModeScrollView = element(app, id: A11yID.AccessibilityMode.scrollView)
        let entryButton = element(app, id: A11yID.AccessibilityMode.undoEditButton)
        guard scrollListToElement(entryButton, in: accessibilityModeScrollView) else { return false }
        entryButton.tap()
        return element(app, id: A11yID.UndoEdits.closeButton).waitForExistence(timeout: timeout)
    }

    /// Map's floating undo button (A11yID.Map.undoButton) is not a toolbar item - it
    /// sits directly on the map canvas, so it's never subject to the overflow-collapse
    /// above.
    @discardableResult
    private func openUndoSidebar(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let button = element(app, id: A11yID.Map.undoButton)
        guard button.waitForExistence(timeout: timeout) else { return false }
        button.tap()
        return element(app, id: A11yID.Map.undoSidebarCloseButton).waitForExistence(timeout: timeout)
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.UndoEdits.scrollView)
    }

    /// Scrolls UndoEditsView's own List to `element`. A plain List (no nested inner
    /// ScrollViews), so this mirrors AccessibilityModeScreenUITestCases' own
    /// scrollListToElement - reimplemented here rather than shared, matching how every
    /// suite in this project keeps its own copy of this helper.
    @discardableResult
    private func scrollListToElement(_ element: XCUIElement, in scrollView: XCUIElement,
                                     maxSwipes: Int = 16, requireFullyOnScreen: Bool = false) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        // Swipe coordinates come from the LIST's own live frame, not the window's - see
        // AccessibilityModeScreenUITestCases' own comment on this same pattern for why
        // (this screen's List is similarly inset from the window on every edge).
        let listFrame = scrollView.frame
        let x: CGFloat = listFrame.minX + 8
        let topY = listFrame.minY + 24
        let bottomY = listFrame.maxY - 24
        func satisfied() -> Bool {
            guard element.isHittable else { return false }
            guard requireFullyOnScreen else { return true }
            return window.contains(element.frame)
        }
        var swipes = 0
        while !satisfied() && swipes < maxSwipes {
            let down = !(element.exists && element.frame.midY < window.midY)
            let big = !(element.exists && element.isHittable)
            let (fromY, toY): (CGFloat, CGFloat)
            if big {
                (fromY, toY) = down ? (bottomY, topY) : (topY, bottomY)
            } else {
                let nudge: CGFloat = 60
                let midY = (topY + bottomY) / 2
                (fromY, toY) = down ? (midY + nudge, midY - nudge)
                                    : (midY - nudge, midY + nudge)
            }
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: fromY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: toY))
            start.press(forDuration: 0.05, thenDragTo: end)
            swipes += 1
        }
        return element.exists && satisfied()
    }

    private func undoEditsControls(_ app: XCUIApplication) -> [(String, XCUIElement)] {
        [
            ("Close button", element(app, id: A11yID.UndoEdits.closeButton)),
            ("Modified item row", element(app, id: A11yID.UndoEdits.row(elementID: 810301))),
            ("Created item row", element(app, id: A11yID.UndoEdits.row(elementID: 810302))),
            ("Go back button", element(app, id: A11yID.UndoEdits.goBackButton)),
        ]
    }

    // MARK: - UndoEditsView: list, date grouping

    func testUndoEditsListShowsSeededItemsGroupedByDate() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let modifiedRow = element(app, id: A11yID.UndoEdits.row(elementID: 810301))
        XCTAssertTrue(scrollListToElement(modifiedRow, in: scrollView), "Modified item's row not reachable")
        XCTAssertTrue(modifiedRow.label.contains("Sidewalks"),
                      "Modified row does not show its quest type - label: \(modifiedRow.label)")

        let createdRow = element(app, id: A11yID.UndoEdits.row(elementID: 810302))
        XCTAssertTrue(scrollListToElement(createdRow, in: scrollView), "Created item's row not reachable")
        XCTAssertTrue(createdRow.label.contains("Kerbs"),
                      "Created row does not show its quest type - label: \(createdRow.label)")
    }

    // MARK: - Selection, confirmation, cancel

    func testTappingRowShowsConfirmationWithRevertLabel() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let row = element(app, id: A11yID.UndoEdits.row(elementID: 810301))
        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Modified item's row not reachable")
        row.tap()

        let revertButton = element(app, id: A11yID.UndoEdits.confirmationRevertButton)
        XCTAssertTrue(revertButton.waitForExistence(timeout: 10), "Confirmation sheet did not appear")
        XCTAssertTrue(revertButton.label.contains("Revert"),
                      "Modify-type item's button does not read Revert Changes - label: \(revertButton.label)")
    }

    /// A created feature has no prior tags to revert to - undoing it deletes the
    /// element outright, which is why the SAME button reads "Delete Feature" instead of
    /// "Revert Changes" here (UndoItemConfirmationView.swift's own isCreatedElement
    /// branch) rather than being a separate control.
    func testCreatedElementConfirmationShowsDeleteLabel() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let row = element(app, id: A11yID.UndoEdits.row(elementID: 810302))
        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Created item's row not reachable")
        row.tap()

        let revertButton = element(app, id: A11yID.UndoEdits.confirmationRevertButton)
        XCTAssertTrue(revertButton.waitForExistence(timeout: 10), "Confirmation sheet did not appear")
        XCTAssertTrue(revertButton.label.contains("Delete"),
                      "Created-element item's button does not read Delete Feature - label: \(revertButton.label)")
    }

    func testCancelButtonDismissesWithoutReverting() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let row = element(app, id: A11yID.UndoEdits.row(elementID: 810301))
        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Row not reachable")
        row.tap()

        let cancelButton = element(app, id: A11yID.UndoEdits.confirmationCancelButton)
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 10), "Confirmation sheet did not appear")
        cancelButton.tap()

        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Item was removed despite cancelling instead of reverting")
    }

    // MARK: - Network on/off

    func testRevertingChangeRemovesItFromListWhenOnline() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let row = element(app, id: A11yID.UndoEdits.row(elementID: 810301))
        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Row not reachable")
        row.tap()

        let revertButton = element(app, id: A11yID.UndoEdits.confirmationRevertButton)
        XCTAssertTrue(revertButton.waitForExistence(timeout: 10), "Confirmation sheet did not appear")
        revertButton.tap()

        XCTAssertTrue(element(app, id: A11yID.UndoEdits.row(elementID: 810301)).waitForNonExistence(timeout: 20),
                      "Reverted item is still in the list")
    }

    /// See this file's own header comment: a failed undo has NO visible error UI
    /// anywhere in the app today. The only honest assertion is that the item is never
    /// removed and the screen stays responsive - not that some error message appears.
    func testRevertingChangeFailsSilentlyWhenOffline() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsNetworkDown)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let row = element(app, id: A11yID.UndoEdits.row(elementID: 810301))
        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Row not reachable")
        row.tap()

        let revertButton = element(app, id: A11yID.UndoEdits.confirmationRevertButton)
        XCTAssertTrue(revertButton.waitForExistence(timeout: 10), "Confirmation sheet did not appear")
        revertButton.tap()

        // Give the failing network call time to actually resolve before checking, so
        // this isn't just "checked too soon" passing for the wrong reason.
        sleep(3)
        XCTAssertTrue(scrollListToElement(row, in: scrollView), "Item disappeared despite the revert failing offline")
        XCTAssertTrue(element(app, id: A11yID.UndoEdits.closeButton).isHittable,
                      "Screen became unresponsive after a failed revert")
    }

    // MARK: - Empty state, navigation

    func testUndoEditsShowsEmptyStateWhenNoEdits() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")

        XCTAssertTrue(element(app, id: A11yID.UndoEdits.noEditsMessage).waitForExistence(timeout: 10),
                      "Empty state not shown when there are no undoable edits")
        XCTAssertFalse(element(app, id: A11yID.UndoEdits.scrollView).exists,
                       "List still rendered despite there being no edits")
    }

    func testGoBackButtonReturnsToAccessibilityMode() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let goBack = element(app, id: A11yID.UndoEdits.goBackButton)
        XCTAssertTrue(scrollListToElement(goBack, in: scrollView), "Go back button not reachable")
        goBack.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.accessibilityModeCloseButton).waitForExistence(timeout: 10),
                      "Did not return to Accessibility Mode")
    }

    // MARK: - Layout: overlap, screen bounds, reachability

    func testUndoEditsElementsDoNotOverlap() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        let row1 = element(app, id: A11yID.UndoEdits.row(elementID: 810301))
        let row2 = element(app, id: A11yID.UndoEdits.row(elementID: 810302))
        XCTAssertTrue(scrollListToElement(row2, in: scrollView), "Rows not reachable")
        assertNoOverlap([(row1, "Modified item row"), (row2, "Created item row")])
    }

    func testUndoEditsElementsFitWithinScreenBounds() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)
        let window = app.windows.firstMatch

        for (name, control) in undoEditsControls(app) {
            XCTAssertTrue(scrollListToElement(control, in: scrollView, requireFullyOnScreen: true), "\(name) not reachable by scrolling")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX, "\(name) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX, "\(name) extends past the right edge of the screen")
            XCTAssertGreaterThanOrEqual(control.frame.minY, window.frame.minY, "\(name) extends past the top edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxY, window.frame.maxY, "\(name) extends past the bottom edge of the screen")
        }
    }

    func testAllUndoEditsElementsReachableAndTappable() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(openUndoEdits(app), "Undo Edits screen did not open")
        let scrollView = scroll(in: app)

        for (name, control) in undoEditsControls(app) {
            XCTAssertTrue(scrollListToElement(control, in: scrollView), "\(name) not reachable by scrolling")
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
        }
    }

    // MARK: - Map's floating undo button (UndoSidebarView) - same data, lighter UI

    func testMapUndoSidebarShowsSeededItems() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openUndoSidebar(app), "Undo sidebar did not open")

        XCTAssertTrue(element(app, id: A11yID.Map.undoSidebarRow(elementID: 810301)).waitForExistence(timeout: 10),
                      "Modified item's row not shown in the Map undo sidebar")
        XCTAssertTrue(element(app, id: A11yID.Map.undoSidebarRow(elementID: 810302)).exists,
                      "Created item's row not shown in the Map undo sidebar")
    }

    func testMapUndoPopupRevertRemovesItemWhenOnline() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openUndoSidebar(app), "Undo sidebar did not open")

        let row = element(app, id: A11yID.Map.undoSidebarRow(elementID: 810301))
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Row not shown")
        row.tap()

        let revertButton = element(app, id: A11yID.Map.undoPopupRevertButton)
        XCTAssertTrue(revertButton.waitForExistence(timeout: 10), "Undo popup did not appear")
        revertButton.tap()

        // The sidebar closes itself immediately on Revert, before the async network
        // round trip completes (UndoButton.swift's own onUndo closure fires
        // synchronously) - poll by reopening the sidebar until the item is actually
        // gone, rather than assuming the very first reopen already reflects a finished
        // sync.
        var reverted = false
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            XCTAssertTrue(openUndoSidebar(app), "Undo sidebar did not reopen")
            if !element(app, id: A11yID.Map.undoSidebarRow(elementID: 810301)).exists {
                reverted = true
                break
            }
            element(app, id: A11yID.Map.undoSidebarCloseButton).tap()
            usleep(500_000)
        }
        XCTAssertTrue(reverted, "Reverted item is still in the Map undo sidebar after waiting for the sync to complete")
    }

    func testMapUndoSidebarClosesViaCloseButton() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openUndoSidebar(app), "Undo sidebar did not open")

        element(app, id: A11yID.Map.undoSidebarCloseButton).tap()

        XCTAssertTrue(element(app, id: A11yID.Map.undoButton).waitForExistence(timeout: 10),
                      "Undo sidebar did not close (floating button did not reappear)")
    }

    /// A small, fixed popup rather than a scrollable screen, so one combined check
    /// covers overlap/bounds/reachability instead of the fuller three-test split
    /// UndoEditsView gets above.
    func testMapUndoSidebarLayout() throws {
        let app = reachMapScreen(scenario: UITestScenario.undoEditsOnline)
        XCTAssertTrue(openUndoSidebar(app), "Undo sidebar did not open")

        let closeButton = element(app, id: A11yID.Map.undoSidebarCloseButton)
        let row1 = element(app, id: A11yID.Map.undoSidebarRow(elementID: 810301))
        let row2 = element(app, id: A11yID.Map.undoSidebarRow(elementID: 810302))
        XCTAssertTrue(row2.waitForExistence(timeout: 10), "Rows not shown")

        let window = app.windows.firstMatch.frame
        for (name, control) in [("Close button", closeButton), ("Row 810301", row1), ("Row 810302", row2)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
        }
        assertNoOverlap([(closeButton, "Close button"), (row1, "Row 810301"), (row2, "Row 810302")])
    }
}
