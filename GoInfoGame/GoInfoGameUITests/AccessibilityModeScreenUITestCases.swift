//
//  AccessibilityModeScreenUITestCases.swift
//  GoInfoGameUITests
//
//  The Accessibility (Screen Reader) Mode screen (GoInfoGame/UI/Map/Accessibility Mode/),
//  reached by tapping A11yID.Map.accessibilityModeButton on the Map screen. Shows the up-
//  to-5 nearest unanswered quests within 250m of the user's location
//  (AccessibilityModeViewModel.filterQuestsNerestToUser), each one a card a screen-reader
//  user can select to answer or hide instead of tapping a map pin directly.
//
//  Fixture: AccessibilityModeOSMElements.json (accessibilityModeOnline/NetworkDown) - 7
//  blank Sidewalks ways placed at known distances/bearings from the fixed UI-test camera
//  (17.4385,78.3610). See that fixture's own "_note" for exactly what each one is; the
//  ones this suite uses by id:
//    700001  40m  North  - nearest
//    700002  90m  East
//    700003  140m South
//    700004  190m West
//    700005  230m North East - farthest of the expected top-5
//    700006  245m South East - within the 250m threshold, but 6th-nearest: excluded by
//            the sort-then-cap-to-5 logic specifically, not the distance filter
//    700007  300m North      - beyond the 250m threshold: excluded by the filter itself
//  AccessibilityModeOSMElementsFar.json (accessibilityModeNoNearbyQuests) has 2 more,
//  both 600m+ away, for the empty-list (NoQuestsNearView) scenario.
//
//  Scope: the nearest-quest list itself (sort, distance/direction text, the 5-item cap,
//  re-filtering when the underlying quest data changes), the selection hand-off (row tap
//  -> confirmation sheet -> LongForm, the exact same code LongFormScreenUITestCases
//  already covers in full - not re-tested here), and this screen's own chrome (refresh,
//  go-to-map, screen-bounds, overlap, reachability).
//
//  Deliberately NOT exercised: genuine location movement. The UI-test location mock
//  (LocationManagerDelegate's UITestRuntime.isActive branch) delivers exactly ONE fixed
//  coordinate and never updates again, and the Map suite's GPX-route script explicitly
//  only reaches MapLibre's own user-location layer, not this screen's location consumer
//  (see Scripts/run-map-ui-tests-with-location.sh's own comment) - there is no existing
//  mechanism to simulate a moving user under UI tests. The list's OTHER re-filter trigger
//  (.onChange(of: mapViewModel.items) in AccessibilityModeView.swift, independent of
//  location) needs no location movement at all - hiding a quest changes the underlying
//  data and re-triggers the same filterQuestsNerestToUser call a real location update
//  would, which is what testHidingQuestUpdatesNearestListAndFillsFreedSlot exercises.
//

import XCTest

final class AccessibilityModeScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    /// Mirrors MapScreenUITestCases' own private `trailingToolbarButton` (not visible
    /// across files) - the Map toolbar's trailing items can collapse into iOS 26's
    /// automatic overflow ("More") menu when they don't all fit, and
    /// accessibilityModeButton is one of the items that can land there. See that
    /// method's own comment for why the overflow row is matched by its label text
    /// ("Screen Reader Mode") rather than an identifier - the OS-synthesized row has none.
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

    /// Taps the Map screen's own entry point and waits for this screen's presence signal.
    /// The close button (always in the toolbar) rather than the List: the List doesn't
    /// exist at all when nearestQuest is empty (NoQuestsNearView takes its place instead -
    /// see accessibilityModeNoNearbyQuests), so it can't double as "did the screen open"
    /// for every scenario the way it does in LongForm/Map.
    @discardableResult
    private func openAccessibilityMode(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let entryButton = trailingToolbarButton(app, id: A11yID.Map.accessibilityModeButton, overflowMenuText: "Screen Reader Mode")
        guard entryButton.waitForExistence(timeout: timeout) else { return false }
        entryButton.tap()
        return element(app, id: A11yID.Map.accessibilityModeCloseButton).waitForExistence(timeout: timeout)
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.AccessibilityMode.scrollView)
    }

    /// Scrolls this screen's own List to `element`. A plain ScrollView-backed List (no
    /// nested inner ScrollViews the way LongForm's choice grids have - NearestQuestCard is
    /// a flat HStack), so the base class's own `scrollToElement` would work for plain
    /// reachability, but the stricter `requireFullyOnScreen` mode (this suite's own bounds
    /// test) is LongForm-local, not shared - reimplemented here rather than promoted to
    /// the base class, matching how LongFormScreenUITestCases already keeps its own copy.
    @discardableResult
    private func scrollListToElement(_ element: XCUIElement, in scrollView: XCUIElement,
                                     maxSwipes: Int = 16, requireFullyOnScreen: Bool = false) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        // Swipe coordinates come from the LIST's own live frame, not the window's - this
        // screen's List sits inset from the window on every edge (`.padding()` on the
        // outer ZStack, plus the safe-area/home-indicator margin `.ignoresSafeArea`
        // doesn't actually erase), confirmed directly: the List's own frame bottom edge
        // sat ~26pt above the window's, so a swipe computed from the window's bottom
        // landed below the List entirely and never scrolled it, no matter how many
        // attempts - every element past whatever was on-screen at rest (the bottom bar)
        // was consequently unreachable. `x` similarly comes just inside the List's own
        // left edge rather than an assumed offset from the window's.
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

    /// A representative control from every visible part of the screen, used by both
    /// layout tests below. Quest cards from accessibilityModeOnline's own top-5.
    private func accessibilityModeControls(_ app: XCUIApplication) -> [(String, XCUIElement)] {
        [
            ("Close button", element(app, id: A11yID.Map.accessibilityModeCloseButton)),
            ("Filter button", element(app, id: A11yID.AccessibilityMode.filterButton)),
            ("Quest count label", element(app, id: A11yID.AccessibilityMode.questCountLabel)),
            ("Refresh button", element(app, id: A11yID.AccessibilityMode.refreshButton)),
            ("Quest card 700001", element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001))),
            ("Quest card 700003", element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700003))),
            ("Quest card 700005", element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700005))),
            ("Undo edits button", element(app, id: A11yID.AccessibilityMode.undoEditButton)),
            ("Go to map button", element(app, id: A11yID.AccessibilityMode.goToMapButton)),
        ]
    }

    // MARK: - Nearest-quest list: sort, cap, distance threshold

    /// Also spot-checks the "Showing N quests" header against the actual card count -
    /// both readings of "how many quests are near me" (the header text and the list
    /// itself) have to agree.
    func testAccessibilityModeShowsUpToFiveNearestQuestsSortedByDistance() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let countLabel = element(app, id: A11yID.AccessibilityMode.questCountLabel)
        XCTAssertTrue(scrollListToElement(countLabel, in: scrollView), "Quest count label not reachable")
        XCTAssertTrue(countLabel.label.contains("5"),
                      "Quest count header does not read 5 - label: \(countLabel.label)")

        // Nearest-to-farthest: 40/90/140/190/230m.
        let expectedOrder: [Int64] = [700001, 700002, 700003, 700004, 700005]
        let cards = expectedOrder.map { element(app, id: A11yID.AccessibilityMode.questCard(elementID: $0)) }
        XCTAssertTrue(scrollListToElement(cards.last!, in: scrollView),
                      "Farthest of the expected top-5 quest cards not reachable")

        for (index, card) in cards.enumerated() {
            XCTAssertTrue(card.exists, "Quest card \(expectedOrder[index]) missing from the top-5 list")
        }
        for i in 0..<(cards.count - 1) {
            XCTAssertLessThan(cards[i].frame.midY, cards[i + 1].frame.midY,
                              "Quest card \(expectedOrder[i]) is not above \(expectedOrder[i + 1]) - list is not sorted by distance")
        }

        XCTAssertFalse(element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700006)).exists,
                       "6th-nearest quest (within the 250m threshold) shown despite the 5-item cap")
    }

    func testAccessibilityModeExcludesQuestsBeyondDistanceThreshold() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        // Scroll through everything the list actually has first - if the 300m element
        // existed anywhere in it, this would have materialized it too (List virtualization
        // only renders rows once scrolled near - see ScreenshotOnFailureUITestCase's own
        // scrollToElement comment).
        let farthestShown = element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700005))
        XCTAssertTrue(scrollListToElement(farthestShown, in: scrollView), "Nearest-quest list not reachable")

        XCTAssertFalse(element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700007)).exists,
                       "Quest beyond the 250m distance threshold (300m) appeared in the nearest-quest list")
    }

    /// NearestQuestCard's text is what a screen-reader user actually hears - this is the
    /// one place in this suite where getting the exact wording right matters as much as
    /// the underlying data being correct.
    func testAccessibilityModeCardShowsDistanceAndDirectionText() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let card = element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700002)) // 90m, East
        XCTAssertTrue(scrollListToElement(card, in: scrollView), "Quest card not reachable")
        XCTAssertTrue(card.label.contains("You are 90 meters from \"Sidewalks\", to the East."),
                      "Card text does not match the expected distance/type/direction - label: \(card.label)")
    }

    // MARK: - Selection hand-off

    /// Proves the row tap -> confirmation -> LongForm hand-off works, not LongForm's own
    /// prefill/save behavior (LongFormScreenUITestCases already covers that in full via
    /// the exact same QuestSheetView/LongForm code this screen reuses).
    func testSelectingQuestShowsConfirmationThenAnswerOpensLongForm() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let card = element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001))
        XCTAssertTrue(scrollListToElement(card, in: scrollView), "Quest card not reachable")
        card.tap()

        let answerButton = element(app, id: A11yID.AccessibilityMode.confirmationAnswerButton)
        XCTAssertTrue(answerButton.waitForExistence(timeout: 10), "Selection confirmation sheet did not appear")
        answerButton.tap()

        XCTAssertTrue(element(app, id: A11yID.LongForm.dismissButton).waitForExistence(timeout: 15),
                      "LongForm did not open after choosing to answer the selected quest")
    }

    /// The "list updates as the underlying data changes" requirement - see this file's
    /// own header comment for why a real moving location can't be exercised instead.
    /// Hiding the nearest quest must both remove its own card AND let the previously
    /// cap-excluded 6th-nearest quest take the freed slot - proving the list actually
    /// re-filters against the new data (AccessibilityModeView's own
    /// .onChange(of: mapViewModel.items)), not just removing one row in place.
    func testHidingQuestUpdatesNearestListAndFillsFreedSlot() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let nearest = element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001))
        XCTAssertTrue(scrollListToElement(nearest, in: scrollView), "Nearest quest card not reachable")
        nearest.tap()

        let hideButton = element(app, id: A11yID.AccessibilityMode.confirmationHideButton)
        XCTAssertTrue(hideButton.waitForExistence(timeout: 10), "Selection confirmation sheet did not appear")
        hideButton.tap()

        XCTAssertTrue(element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001)).waitForNonExistence(timeout: 10),
                      "Hidden quest's card is still in the nearest-quest list")
        XCTAssertTrue(scrollListToElement(element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700006)), in: scrollView),
                      "6th-nearest quest did not take the freed slot after hiding the closest one")
    }

    func testRefreshListButtonReFiltersAgainstCurrentLocation() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let refresh = element(app, id: A11yID.AccessibilityMode.refreshButton)
        XCTAssertTrue(scrollListToElement(refresh, in: scrollView), "Refresh button not reachable")
        refresh.tap()

        let card = element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001))
        XCTAssertTrue(scrollListToElement(card, in: scrollView), "Nearest quest card missing after refresh")
    }

    func testAccessibilityModeShowsEmptyStateWhenNoQuestsNearby() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeNoNearbyQuests)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")

        XCTAssertTrue(element(app, id: A11yID.AccessibilityMode.noQuestsMessage).waitForExistence(timeout: 10),
                      "Empty state not shown when every quest is beyond the distance threshold")
        XCTAssertFalse(element(app, id: A11yID.AccessibilityMode.scrollView).exists,
                       "List still rendered despite there being no nearby quests")
    }

    // MARK: - Navigation

    func testGoToMapButtonReturnsToMapScreen() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let goToMap = element(app, id: A11yID.AccessibilityMode.goToMapButton)
        XCTAssertTrue(scrollListToElement(goToMap, in: scrollView), "Go to map button not reachable")
        goToMap.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Did not return to the Map screen")
    }

    // MARK: - Network on/off

    /// The nearest-quest list is a pure local-DB read (mapViewModel.items, already
    /// populated by the Map screen's own successful load) - AccessibilityModeViewModel
    /// never calls the network itself, so this proves the list is genuinely unaffected
    /// by a subsequent outage, rather than assuming it from reading the code.
    func testAccessibilityModeListPopulatesUnderNetworkDownScenario() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeNetworkDown)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        let card = element(app, id: A11yID.AccessibilityMode.questCard(elementID: 700001))
        XCTAssertTrue(scrollListToElement(card, in: scrollView), "Nearest quest card not reachable with network down")
    }

    // MARK: - Layout: overlap, screen bounds, reachability

    func testAccessibilityModeElementsDoNotOverlap() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        // Quest count label / refresh button share one HStack row.
        let countLabel = element(app, id: A11yID.AccessibilityMode.questCountLabel)
        let refresh = element(app, id: A11yID.AccessibilityMode.refreshButton)
        XCTAssertTrue(scrollListToElement(countLabel, in: scrollView), "Quest count label not reachable")
        assertNoOverlap([(countLabel, "Quest count label"), (refresh, "Refresh button")])

        // Undo edits / go to map share one HStack row (or stack at accessibility sizes).
        let undo = element(app, id: A11yID.AccessibilityMode.undoEditButton)
        let goToMap = element(app, id: A11yID.AccessibilityMode.goToMapButton)
        XCTAssertTrue(scrollListToElement(goToMap, in: scrollView), "Bottom bar not reachable")
        assertNoOverlap([(undo, "Undo edits button"), (goToMap, "Go to map button")])

        // A few consecutive quest cards.
        let cards = [700001, 700002, 700003].map {
            (element(app, id: A11yID.AccessibilityMode.questCard(elementID: Int64($0))), "Quest card \($0)")
        }
        assertNoOverlap(cards)
    }

    func testAccessibilityModeElementsFitWithinScreenBounds() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)
        let window = app.windows.firstMatch

        for (name, control) in accessibilityModeControls(app) {
            XCTAssertTrue(scrollListToElement(control, in: scrollView, requireFullyOnScreen: true), "\(name) not reachable by scrolling")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX, "\(name) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX, "\(name) extends past the right edge of the screen")
            XCTAssertGreaterThanOrEqual(control.frame.minY, window.frame.minY, "\(name) extends past the top edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxY, window.frame.maxY, "\(name) extends past the bottom edge of the screen")
        }
    }

    func testAllAccessibilityModeElementsReachableAndTappable() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        XCTAssertTrue(openAccessibilityMode(app), "Accessibility Mode did not open")
        let scrollView = scroll(in: app)

        for (name, control) in accessibilityModeControls(app) {
            XCTAssertTrue(scrollListToElement(control, in: scrollView), "\(name) not reachable by scrolling")
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
        }
    }
}
