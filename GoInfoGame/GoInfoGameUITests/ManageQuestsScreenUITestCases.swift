//
//  ManageQuestsScreenUITestCases.swift
//  GoInfoGameUITests
//
//  ManageQuestsView (GoInfoGame/quests/QuestCategory/UI/ManageQuestsView.swift), reached
//  from both A11yID.Map.manageQuestsButton (Map's own toolbar) and
//  A11yID.AccessibilityMode.filterButton (Accessibility Mode's "tune" icon) - a single
//  zero-parameter view with no configuration difference between the two entry points, so
//  this suite tests the view's own content/behavior once and only re-verifies "it opens
//  from here too" for the second entry point.
//
//  Two sections:
//    FEATURES         one toggle per quest type (Sidewalks/Crossings/Kerbs, from
//                      WorkspaceDetailsWithQuests.json) - NOT a cosmetic preference:
//                      QuestsRepository.applicableQuests filters on it directly, so
//                      toggling a type off removes every one of its quests from both
//                      Map and Accessibility Mode's lists, immediately, no relaunch
//                      needed (confirmed directly by tracing the refresh chain).
//    HIDDEN ELEMENTS   only rendered when non-empty; one row per quest the user hid
//                      elsewhere, with swipe-to-delete and a bulk "Unhide All".
//
//  Network: NOT relevant to this screen specifically (confirmed directly) - every
//  interaction is a synchronous local UserDefaults write (QuestsRepository/
//  HiddenQuestManager), and closing the sheet only triggers a local Realm re-read, no
//  network call. No online/offline scenario is needed here the way LongForm/UndoEdits
//  have.
//
//  Seeding: like the Undo Edits list, HiddenQuestManager's data has no network fetch
//  behind it and nothing else can populate it except actually hiding a quest through a
//  real flow first - UITestStubs.seedHiddenQuests() writes 2 HiddenQuest rows directly
//  to UserDefaults["hiddenElements"] for manageQuestsOnline (810401 "Sidewalks", 810402
//  "Crossings"), the same pattern as seedUndoableChangesets() for the Undo Edits suite.
//

import XCTest

final class ManageQuestsScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    /// Mirrors MapScreenUITestCases' own private `trailingToolbarButton` (not visible
    /// across files) - Map's toolbar trailing items (including manageQuestsButton) can
    /// collapse into iOS 26's automatic overflow ("More") menu when they don't all fit.
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
    private func openManageQuestsFromMap(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let entryButton = trailingToolbarButton(app, id: A11yID.Map.manageQuestsButton, overflowMenuText: "Manage Quests")
        guard entryButton.waitForExistence(timeout: timeout) else { return false }
        entryButton.tap()
        return element(app, id: A11yID.Map.manageQuestsCloseButton).waitForExistence(timeout: timeout)
    }

    @discardableResult
    private func openAccessibilityMode(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let entryButton = trailingToolbarButton(app, id: A11yID.Map.accessibilityModeButton, overflowMenuText: "Screen Reader Mode")
        guard entryButton.waitForExistence(timeout: timeout) else { return false }
        entryButton.tap()
        return element(app, id: A11yID.Map.accessibilityModeCloseButton).waitForExistence(timeout: timeout)
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.ManageQuests.scrollView)
    }

    /// Scrolls ManageQuestsView's own List to `element`. A plain List (no nested inner
    /// ScrollViews), mirrors every other suite's own copy of this helper in this
    /// project.
    @discardableResult
    private func scrollListToElement(_ element: XCUIElement, in scrollView: XCUIElement,
                                     maxSwipes: Int = 16, requireFullyOnScreen: Bool = false) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
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

    /// A plain `.tap()` on a FEATURES toggle lands at its accessibility frame's center -
    /// which, for a SwiftUI `Toggle(isOn:) { Text(title) }`, sits over the row's LABEL
    /// text, not the switch graphic itself (confirmed directly: the toggle's own
    /// `value` stayed "1" after a plain tap). The switch graphic sits at the row's
    /// trailing edge, so this taps there instead.
    @discardableResult
    private func tapToggle(_ toggle: XCUIElement) -> Bool {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        return true
    }

    private func manageQuestsControls(_ app: XCUIApplication) -> [(String, XCUIElement)] {
        [
            ("Close button", element(app, id: A11yID.Map.manageQuestsCloseButton)),
            ("Sidewalks toggle", element(app, id: A11yID.ManageQuests.featureToggle(elementType: "Sidewalks"))),
            ("Crossings toggle", element(app, id: A11yID.ManageQuests.featureToggle(elementType: "Crossings"))),
            ("Kerbs toggle", element(app, id: A11yID.ManageQuests.featureToggle(elementType: "Kerbs"))),
            ("Hidden row 810401", element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810401))),
            ("Hidden row 810402", element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810402))),
            ("Unhide All button", element(app, id: A11yID.ManageQuests.unhideAllButton)),
        ]
    }

    // MARK: - FEATURES section

    func testManageQuestsShowsAllFeatureTypes() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        for elementType in ["Sidewalks", "Crossings", "Kerbs"] {
            let toggle = element(app, id: A11yID.ManageQuests.featureToggle(elementType: elementType))
            XCTAssertTrue(scrollListToElement(toggle, in: scrollView), "\(elementType) toggle not reachable")
            XCTAssertEqual(toggle.value as? String, "1",
                          "\(elementType) toggle is not on by default - value: \(String(describing: toggle.value))")
        }
    }

    /// Not a cosmetic preference - see this file's own header comment. Reuses
    /// accessibilityModeOnline's own fixture (AccessibilityModeOSMElements.json), whose
    /// 7 elements are ALL blank Sidewalks ways, so toggling Sidewalks off must make that
    /// screen's nearest-quest list go empty entirely.
    func testTogglingFeatureOffHidesItsQuestsFromAccessibilityModeList() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        let sidewalksToggle = element(app, id: A11yID.ManageQuests.featureToggle(elementType: "Sidewalks"))
        XCTAssertTrue(scrollListToElement(sidewalksToggle, in: scrollView), "Sidewalks toggle not reachable")
        tapToggle(sidewalksToggle)
        XCTAssertEqual(sidewalksToggle.value as? String, "0",
                      "Sidewalks toggle did not flip off - value: \(String(describing: sidewalksToggle.value))")

        element(app, id: A11yID.Map.manageQuestsCloseButton).tap()
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Did not return to the Map screen after closing Manage Quests")

        // Give the refresh chain (ManageQuestsView.onDisappear -> QuestsPublisher
        // .refreshQuest -> MapViewModel.refreshQuests(), a local DB re-read) a moment to
        // actually complete before checking - it's async relative to the sheet
        // dismiss's own animation completing. Checked on the Map screen itself first
        // (its pins are the most direct signal) before Accessibility Mode, which reads
        // off the same MapViewModel.items.
        var pinsGone = false
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            if app.buttons.matching(identifier: A11yID.Map.questAnnotation).count == 0 {
                pinsGone = true
                break
            }
            usleep(500_000)
        }
        XCTAssertTrue(pinsGone, "Sidewalks quest pins are still on the Map after toggling that feature off")

        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(element(app, id: A11yID.AccessibilityMode.noQuestsMessage).waitForExistence(timeout: 10),
                      "Nearest-quest list still shows Sidewalks quests after toggling that feature off")
    }

    func testTogglingFeatureBackOnRestoresItsQuestsFromAccessibilityModeList() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        let sidewalksToggle = element(app, id: A11yID.ManageQuests.featureToggle(elementType: "Sidewalks"))
        XCTAssertTrue(scrollListToElement(sidewalksToggle, in: scrollView), "Sidewalks toggle not reachable")
        tapToggle(sidewalksToggle)
        tapToggle(sidewalksToggle)

        element(app, id: A11yID.Map.manageQuestsCloseButton).tap()
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Did not return to the Map screen after closing Manage Quests")

        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        XCTAssertTrue(element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001)).waitForExistence(timeout: 10),
                      "Nearest-quest list missing its Sidewalks quests after toggling the feature back on")
    }

    // MARK: - HIDDEN ELEMENTS section

    func testHiddenElementsSectionHiddenWhenNoneHidden() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")

        XCTAssertFalse(element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810401)).exists,
                       "A hidden-elements row exists despite nothing being hidden")
        XCTAssertFalse(element(app, id: A11yID.ManageQuests.unhideAllButton).exists,
                       "Unhide All button exists despite the Hidden Elements section having nothing to show")
    }

    func testHiddenElementsSectionShowsSeededItems() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        let row1 = element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810401))
        XCTAssertTrue(scrollListToElement(row1, in: scrollView), "Seeded hidden row 810401 not reachable")
        XCTAssertTrue(row1.label.contains("Sidewalks"), "Hidden row 810401 does not show its name - label: \(row1.label)")

        let row2 = element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810402))
        XCTAssertTrue(scrollListToElement(row2, in: scrollView), "Seeded hidden row 810402 not reachable")
        XCTAssertTrue(row2.label.contains("Crossings"), "Hidden row 810402 does not show its name - label: \(row2.label)")
    }

    func testUnhideAllButtonClearsHiddenElementsSection() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        let unhideAll = element(app, id: A11yID.ManageQuests.unhideAllButton)
        XCTAssertTrue(scrollListToElement(unhideAll, in: scrollView), "Unhide All button not reachable")
        unhideAll.tap()

        XCTAssertTrue(element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810401)).waitForNonExistence(timeout: 10),
                      "Hidden row 810401 still present after Unhide All")
        XCTAssertFalse(element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810402)).exists,
                       "Hidden row 810402 still present after Unhide All")
        XCTAssertFalse(unhideAll.exists, "Unhide All button still present despite the section having nothing left")
    }

    /// The native List swipe-to-delete gesture ("Delete" button is OS-synthesized, not
    /// app UI - matched by its fixed English label, the same narrow exception this
    /// project already makes for the iOS 26 toolbar overflow's "More" menu).
    func testSwipeToDeleteRemovesOnlyThatHiddenElementRow() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        let row1 = element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810401))
        XCTAssertTrue(scrollListToElement(row1, in: scrollView), "Hidden row 810401 not reachable")
        row1.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Native swipe-to-delete action did not appear")
        deleteButton.tap()

        XCTAssertTrue(row1.waitForNonExistence(timeout: 10), "Row 810401 still present after swipe-to-delete")
        XCTAssertTrue(element(app, id: A11yID.ManageQuests.hiddenRow(elementID: 810402)).exists,
                      "Row 810402 was also removed - swipe-to-delete should only remove the swiped row")
    }

    // MARK: - Second entry point

    func testOpeningFromAccessibilityModeFilterButtonShowsContent() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")

        let filterButton = element(app, id: A11yID.AccessibilityMode.filterButton)
        XCTAssertTrue(filterButton.waitForExistence(timeout: 10), "Filter button not reachable")
        filterButton.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.manageQuestsCloseButton).waitForExistence(timeout: 10),
                      "Manage Quests sheet did not open from Accessibility Mode's filter button")
        let scrollView = scroll(in: app)
        let sidewalksToggle = element(app, id: A11yID.ManageQuests.featureToggle(elementType: "Sidewalks"))
        XCTAssertTrue(scrollListToElement(sidewalksToggle, in: scrollView), "Sidewalks toggle not reachable")

        element(app, id: A11yID.Map.manageQuestsCloseButton).tap()
        XCTAssertTrue(element(app, id: A11yID.Map.accessibilityModeCloseButton).waitForExistence(timeout: 10),
                      "Did not return to Accessibility Mode after closing Manage Quests")
    }

    // MARK: - Layout: overlap, screen bounds, reachability

    func testManageQuestsElementsDoNotOverlap() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        // "HIDDEN ELEMENTS" label and "Unhide All" share one row (stacked instead at
        // large accessibility text) - the one place on this screen two independent
        // elements sit side by side and are genuinely at risk of overlapping. Separate
        // List rows (the toggles, the hidden-element rows) are never a meaningful
        // overlap check - List guarantees non-overlapping rows by construction.
        let hiddenLabel = element(app, id: A11yID.ManageQuests.hiddenElementsLabel)
        let unhideAll = element(app, id: A11yID.ManageQuests.unhideAllButton)
        XCTAssertTrue(scrollListToElement(unhideAll, in: scrollView), "Unhide All button not reachable")
        assertNoOverlap([(hiddenLabel, "Hidden Elements label"), (unhideAll, "Unhide All button")])
    }

    func testManageQuestsElementsFitWithinScreenBounds() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)
        let window = app.windows.firstMatch

        for (name, control) in manageQuestsControls(app) {
            XCTAssertTrue(scrollListToElement(control, in: scrollView, requireFullyOnScreen: true), "\(name) not reachable by scrolling")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX, "\(name) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX, "\(name) extends past the right edge of the screen")
            XCTAssertGreaterThanOrEqual(control.frame.minY, window.frame.minY, "\(name) extends past the top edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxY, window.frame.maxY, "\(name) extends past the bottom edge of the screen")
        }
    }

    func testAllManageQuestsElementsReachableAndTappable() throws {
        let app = reachMapScreen(scenario: UITestScenario.manageQuestsOnline)
        XCTAssertTrue(openManageQuestsFromMap(app), "Manage Quests sheet did not open")
        let scrollView = scroll(in: app)

        for (name, control) in manageQuestsControls(app) {
            XCTAssertTrue(scrollListToElement(control, in: scrollView), "\(name) not reachable by scrolling")
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
        }
    }
}
