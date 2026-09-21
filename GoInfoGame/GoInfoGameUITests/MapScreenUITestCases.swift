//
//  MapScreenUITestCases.swift
//  GoInfoGameUITests
//
//  The Map screen (UI/Map/MapView.swift), reached by selecting a workspace on the
//  Workspaces screen. mapWithQuestClusters is the only scenario that reaches it: workspace
//  222, "Copy from Stage Kondapur Dataset" (WorkspacesSingle.json - the same single-
//  eligible-workspace fixture workspacesSingleAutoRedirect uses), whose details response
//  (WorkspaceDetailsWithQuests.json) is now a real captured payload with a genuinely
//  populated longFormQuestDef (3 quest_query rules: sidewalks, crossings, kerbs).
//  WorkspacesListView's real auto-redirect path does the rest: it fires on its own, calls
//  fetchLongQuestsFor for real, and that is what saves "workspaceID" to Keychain and
//  navigates to MapView - none of that is seeded artificially.
//
//  MapOSMElements.json is also a real captured response: 973 elements (515 nodes, 458
//  ways) covering Kondapur, Hyderabad's real ~2km bounds (17.43-17.45N, 78.35-78.37E).
//  LocationManagerDelegate's UI-test location bypass was moved to match this area
//  specifically - there is no auto-fit-to-loaded-data camera logic anywhere in
//  CustomMap/MapView, so the map's initial camera stays wherever location puts it
//  regardless of where the fetched elements are, and the app's own dead legacy stub
//  fixtures were all Seattle-area data, which is what the coordinate happened to default
//  to before this scenario needed real Kondapur data to actually be on screen.
//
//  Exact cluster counts are not predictable in advance from data this size and real-world
//  density - see testClusterAnnotationShowsCorrectCount's own comment for what is (and
//  is not) asserted about it.
//
//  Floating buttons and toolbar items are positioned via fixed top/bottom/leading/trailing
//  padding within the screen's own bounds, not inside a ScrollView (unlike every other
//  screen tested so far) - so "reachable on a low-resolution screen" is checked here as
//  "measures within the screen's own bounds", not via scrollToElement.
//
//  Beyond chrome (toolbar, floating buttons, clustering), this suite also covers actions
//  and flows: what happens when each button/gesture is actually triggered, not just that
//  it exists. Scope deliberately stops at "the right sheet/screen opened" - the content
//  of what opens (Manage Quests' toggles, the satellite picker's server list, a quest's
//  actual answer form) is out of scope, since none of those have their own identifiers
//  and would mean matching on label text throughout someone else's screen. Two flows are
//  intentionally reduced to "tapping this doesn't crash, the screen is still usable
//  afterward" rather than asserting the real effect: My Location's recenter depends on
//  MapLibre's own user-location layer (separate from this app's LocationManagerDelegate
//  mock, and not reliably controllable in the Simulator - see that file's own comment on
//  CoreLocation flakiness), and zoom in/out have no on-screen text anywhere showing the
//  current zoom level to assert against.
//

import XCTest

final class MapScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    /// Launches under mapWithQuestClusters, waits through the real Workspaces ->
    /// auto-redirect -> Map flow, and confirms landing on the Map screen. Map has no
    /// single "title" element the way other screens do, so the workspace-name toolbar
    /// button (always present) is the landing signal.
    @discardableResult
    private func reachMapScreen(file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: UITestScenario.mapWithQuestClusters)

        let workspaceTitle = element(app, id: A11yID.Map.workspaceTitleButton)
        XCTAssertTrue(workspaceTitle.waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow",
                      file: file, line: line)
        return app
    }

    /// Finds a top-bar trailing button, falling back to iOS 26's toolbar overflow ("...")
    /// menu if it is not directly visible - automatic SwiftUI/UIKit behavior when the
    /// toolbar cannot fit every trailing item at once, not something this app's own code
    /// controls (confirmed: no #available(iOS 26, *) branching exists for this - the
    /// existing toolbar item ordering just already anticipates it). "More" is the
    /// system's own label for that control; if a different OS version uses another label
    /// this falls through to reporting the button not found, same as today.
    ///
    /// `overflowMenuText`, when passed, is what to look for once an item lands in that
    /// menu - confirmed directly (via a captured accessibility hierarchy dump) that the
    /// row iOS synthesizes there is a brand new element built from the toolbar item's
    /// icon/title, not the original SwiftUI view: it shows the visible title as its
    /// label ("Screen Reader Mode", "Manage Quests") but has no accessibilityIdentifier
    /// at all - unlike every other element in that same dump, it has no `identifier`
    /// field. That popover is an OS-owned surface, not app UI, so matching its fixed
    /// English label here is a deliberate, narrow exception to "never match on label
    /// text" (see A11yID.swift's own doc comment): once the OS discards the identifier
    /// there is nothing else left to key off of. Mirrors the same en-locale assumption
    /// this suite already makes for its alert titles (see
    /// testTappingWorkspaceNameShowsChangeWorkspaceConfirmation). Callers that never
    /// collapse into the overflow (syncButton - deliberately ordered first, see its
    /// ToolbarItem) omit this and get the old identifier-only behavior.
    private func trailingToolbarButton(_ app: XCUIApplication, id: String, overflowMenuText: String? = nil) -> XCUIElement {
        let direct = element(app, id: id)
        if direct.waitForExistence(timeout: 5) {
            return direct
        }

        guard let overflowMenuText else { return direct }

        // The popover may already be open from an earlier call in the same test (both
        // collapsed items share one "More" menu) - check for the row before tapping
        // "More" again, since tapping it a second time while already open dismisses it
        // instead of finding the second item.
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

    /// A screen point, after zooming in enough to spread the real data out, that clears
    /// every currently-visible quest/cluster annotation by a safe margin - so a
    /// long-press there lands on empty map, the same way CustomMap.swift's own
    /// long-press handler treats it (it only proximity-checks against annotations
    /// actually on screen, not against geography this suite has no way to query).
    /// Returns nil if this real dataset's density leaves no such point even after
    /// zooming all the way in - treated as "not testable on this data", not a failure,
    /// the same way this suite already treats the compass button/biometric toggle's
    /// absence.
    private func emptyMapPoint(_ app: XCUIApplication) -> CGPoint? {
        let window = app.windows.firstMatch
        let annotationFrames = app.buttons.matching(identifier: A11yID.Map.clusterAnnotation).allElementsBoundByIndex.map(\.frame)
            + app.buttons.matching(identifier: A11yID.Map.questAnnotation).allElementsBoundByIndex.map(\.frame)

        // Corners, inset just enough to stay clear of the toolbar/floating buttons -
        // checked in this order since corners are where a dense, roughly-centered
        // real-world dataset is least likely to still have coverage after zooming in.
        let margin: CGFloat = 60
        let candidates = [
            CGPoint(x: window.frame.minX + margin, y: window.frame.minY + 160),
            CGPoint(x: window.frame.maxX - margin, y: window.frame.minY + 160),
            CGPoint(x: window.frame.minX + margin, y: window.frame.maxY - 160),
            CGPoint(x: window.frame.maxX - margin, y: window.frame.maxY - 160)
        ]
        return candidates.first { point in
            !annotationFrames.contains { $0.insetBy(dx: -margin, dy: -margin).contains(point) }
        }
    }

    /// Long-presses (CustomMap.swift's own gesture: a `UILongPressGestureRecognizer`
    /// with a 0.5s minimum duration - there is no separate single-tap-to-drop-pin path)
    /// at a specific screen point.
    private func longPress(_ app: XCUIApplication, at point: CGPoint, duration: TimeInterval = 0.6) {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
            .press(forDuration: duration)
    }

    // MARK: - Entry point

    func testMapScreenReachedFromWorkspacesAfterSelectingAWorkspace() throws {
        let app = reachMapScreen()

        XCTAssertTrue(app.buttons[A11yID.Map.profileButton].exists, "Profile button not found on the Map screen")
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).exists, "Workspace title button not found")
        // Confirms this genuinely left the Workspaces screen, not a case where both
        // screens' elements happen to coexist mid-transition.
        XCTAssertFalse(app.staticTexts[A11yID.Workspaces.title].exists,
                       "Workspaces title still present - did not fully transition to the Map screen")
    }

    // MARK: - Floating buttons

    func testAllFloatingButtonsAreVisibleAndAccessible() throws {
        let app = reachMapScreen()

        let buttons: [(XCUIElement, String)] = [
            (element(app, id: A11yID.Map.layersButton), "Layers button"),
            (element(app, id: A11yID.Map.downloadButton), "Download button"),
            (element(app, id: A11yID.Map.undoButton), "Undo button"),
            (element(app, id: A11yID.Map.zoomInButton), "Zoom in button"),
            (element(app, id: A11yID.Map.zoomOutButton), "Zoom out button"),
            (element(app, id: A11yID.Map.myLocationButton), "My location button")
        ]

        // A tiny tolerance, not a loosened standard: FloatingActionButton's frame measured
        // 43.999999999999986pt on a real run - floating-point rounding on an element
        // authored at exactly 44pt, not an actual half-a-pixel design shortfall (confirmed:
        // its own source frames the icon at 44x44 with no other sizing in play). A strict
        // >= would fail a button that is, for any real purpose, exactly on the guideline.
        let tapTargetTolerance: CGFloat = 0.5

        for (button, description) in buttons {
            XCTAssertTrue(button.waitForExistence(timeout: 15), "\(description) not found")
            XCTAssertTrue(button.isHittable, "\(description) exists but is not tappable")
            XCTAssertGreaterThanOrEqual(button.frame.height, Self.minimumTapTarget - tapTargetTolerance,
                                        "\(description) is shorter than the 44pt minimum tap target")
            XCTAssertGreaterThanOrEqual(button.frame.width, Self.minimumTapTarget - tapTargetTolerance,
                                        "\(description) is narrower than the 44pt minimum tap target")
        }
    }

    /// CompassButtonView only renders once the map is rotated off north - simulating a
    /// rotation gesture reliably via XCUITest is not attempted here, so (like the Profile
    /// screen's biometric toggle) its absence is not itself a failure; this only asserts
    /// positively about it when it happens to be present.
    func testCompassButtonIsUsableWhenPresent() throws {
        let app = reachMapScreen()

        let compass = element(app, id: A11yID.Map.compassButton)
        guard compass.waitForExistence(timeout: 3) else { return }
        XCTAssertTrue(compass.isHittable, "Compass button exists but is not tappable")
    }

    // MARK: - Top bar

    func testTopBarElementsAreVisibleAndAccessible() throws {
        let app = reachMapScreen()

        XCTAssertTrue(app.buttons[A11yID.Map.profileButton].isHittable, "Profile button not tappable")
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).exists, "Workspace title button not found")

        XCTAssertTrue(trailingToolbarButton(app, id: A11yID.Map.syncButton).exists, "Sync button not accessible")
        XCTAssertTrue(trailingToolbarButton(app, id: A11yID.Map.accessibilityModeButton, overflowMenuText: "Screen Reader Mode").exists,
                      "Accessibility mode button not accessible")
        XCTAssertTrue(trailingToolbarButton(app, id: A11yID.Map.manageQuestsButton, overflowMenuText: "Manage Quests").exists,
                      "Manage quests button not accessible")
    }

    /// The inner ScrollView has no accessibilityIdentifier of its own (see the comment at
    /// its declaration in MapView.swift: the parent's .accessibilityElement(children:
    /// .combine) makes one structurally unreachable regardless), so the full title being
    /// present in workspaceTitleButton's combined accessibility label - which already
    /// includes the complete, untruncated title string regardless of how many lines it
    /// wraps to visually - is what this asserts. That combined label is the same one
    /// VoiceOver itself would read, so it stands in for "fully accessible" here better
    /// than measuring rendered line count would.
    func testWorkspaceNameShowsFullTitle() throws {
        let app = reachMapScreen()

        let workspaceTitle = element(app, id: A11yID.Map.workspaceTitleButton)
        XCTAssertTrue(workspaceTitle.waitForExistence(timeout: 15), "Workspace title button not found")
        // Matches WorkspacesSingle.json's real title for workspace 222 ("Copy from Stage
        // Kondapur Dataset") - confirms the real title text made it all the way from the
        // Workspaces fetch through the auto-redirect into Map's own toolbar.
        XCTAssertTrue(workspaceTitle.label.contains("Kondapur Dataset"),
                      "Workspace title does not show the expected workspace name - label was: \(workspaceTitle.label)")
    }

    func testTappingWorkspaceNameShowsChangeWorkspaceConfirmation() throws {
        let app = reachMapScreen()

        element(app, id: A11yID.Map.workspaceTitleButton).tap()

        let alert = app.alerts["Do you want to change the workspace?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Change-workspace confirmation did not appear")
        XCTAssertTrue(alert.buttons["Cancel"].exists, "Confirmation missing a Cancel button")
        XCTAssertTrue(alert.buttons["Yes"].exists, "Confirmation missing a Yes button")

        alert.buttons["Cancel"].tap()
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 5),
                      "Left the Map screen despite cancelling the change-workspace confirmation")
    }

    // MARK: - Clustering

    /// MapOSMElements.json is now a real captured response: 973 elements (515 nodes, 458
    /// ways), of which 457 sidewalk ways + 1 crossing way match WorkspaceDetailsWithQuests
    /// .json's quest_query rules (0 nodes match its "barrier=kerb" rule - none of the
    /// captured nodes carry that tag) and so become quest annotations; the other 515 nodes
    /// only exist as those ways' geometry. At that real-world density and geographic
    /// spread (all within Kondapur's real ~2km bounds), predicting an exact cluster count
    /// - or even how many separate clusters form - isn't something this suite can compute
    /// in advance the way the earlier synthetic 6-element fixture allowed; clustering
    /// reacts to screen-pixel distance at whatever zoom the map opens at (CustomMap.swift
    /// refreshClusters(), radius: 50), not just data. So this asserts what is still
    /// genuinely knowable: that clustering fires at all (at least one cluster annotation
    /// appears, given a genuinely dense real dataset) and that its displayed count is a
    /// real, sane number - not that count is exactly some pre-computed value.
    func testClusterAnnotationShowsCorrectCount() throws {
        let app = reachMapScreen()

        // Clustering runs after a debounce (CustomMap.swift schedules it via a 0.2s
        // Timer) plus a background-thread grouping pass, on top of the OSM fetch itself -
        // and this fixture is ~1000x the element count of the one this timeout was
        // originally tuned against, so generous headroom over the earlier value.
        let cluster = element(app, id: A11yID.Map.clusterAnnotation)
        XCTAssertTrue(cluster.waitForExistence(timeout: 40), "No cluster annotation appeared")

        guard let countText = cluster.value as? String, let count = Int(countText) else {
            XCTFail("Cluster annotation's displayed value is not a valid integer - value was: \(String(describing: cluster.value))")
            return
        }
        // > 1: a "cluster" of exactly 1 would mean the clustering algorithm ran but never
        // actually grouped anything, which - given 458 real quest-matching elements in a
        // ~2km area - would itself be a sign something is wrong, not a passing edge case.
        XCTAssertGreaterThan(count, 1, "Cluster annotation's count is not plausible for this dataset: \(count)")
        // <= 458: the absolute ceiling is every quest-matching element in one cluster; a
        // higher number would mean the label is showing something other than a count of
        // real elements.
        XCTAssertLessThanOrEqual(count, 458, "Cluster annotation's count exceeds the total matching elements available: \(count)")
    }

    // MARK: - Layout: overlap

    func testMapElementsDoNotOverlap() throws {
        let app = reachMapScreen()

        var elements: [(element: XCUIElement, name: String)] = [
            (app.buttons[A11yID.Map.profileButton], "Profile button"),
            (element(app, id: A11yID.Map.workspaceTitleButton), "Workspace title button"),
            (element(app, id: A11yID.Map.layersButton), "Layers button"),
            (element(app, id: A11yID.Map.downloadButton), "Download button"),
            (element(app, id: A11yID.Map.undoButton), "Undo button"),
            (element(app, id: A11yID.Map.zoomInButton), "Zoom in button"),
            (element(app, id: A11yID.Map.zoomOutButton), "Zoom out button"),
            (element(app, id: A11yID.Map.myLocationButton), "My location button")
        ]
        for (el, description) in elements {
            XCTAssertTrue(el.waitForExistence(timeout: 15), "\(description) not found")
        }

        // Trailing toolbar items only if directly visible - if iOS 26 collapsed them into
        // the overflow menu they are not simultaneously on screen with everything else,
        // so there is nothing to compare their frames against.
        for id in [A11yID.Map.syncButton, A11yID.Map.accessibilityModeButton, A11yID.Map.manageQuestsButton] {
            let el = element(app, id: id)
            if el.exists { elements.append((el, id)) }
        }

        assertNoOverlap(elements)
    }

    // MARK: - Layout: screen bounds

    /// Floating buttons and toolbar items are positioned via fixed padding within the
    /// screen's own bounds, not inside a ScrollView, so - unlike the Login/Workspaces/
    /// Profile suites - there is no scrollToElement step here. What is checked is that
    /// every element's frame measures fully within the window's frame on whatever screen
    /// size the test runs on.
    func testAllMapElementsFitWithinScreenBounds() throws {
        let app = reachMapScreen()
        let window = app.windows.firstMatch

        var controls: [(String, XCUIElement)] = [
            ("Profile button", app.buttons[A11yID.Map.profileButton]),
            ("Workspace title button", element(app, id: A11yID.Map.workspaceTitleButton)),
            ("Layers button", element(app, id: A11yID.Map.layersButton)),
            ("Download button", element(app, id: A11yID.Map.downloadButton)),
            ("Undo button", element(app, id: A11yID.Map.undoButton)),
            ("Zoom in button", element(app, id: A11yID.Map.zoomInButton)),
            ("Zoom out button", element(app, id: A11yID.Map.zoomOutButton)),
            ("My location button", element(app, id: A11yID.Map.myLocationButton))
        ]
        for id in [A11yID.Map.syncButton, A11yID.Map.accessibilityModeButton, A11yID.Map.manageQuestsButton] {
            let el = element(app, id: id)
            if el.exists { controls.append((id, el)) }
        }

        for (description, control) in controls {
            XCTAssertTrue(control.waitForExistence(timeout: 15), "\(description) not found")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX,
                                        "\(description) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX,
                                     "\(description) extends past the right edge of the screen")
            XCTAssertGreaterThanOrEqual(control.frame.minY, window.frame.minY,
                                        "\(description) extends past the top edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxY, window.frame.maxY,
                                     "\(description) extends past the bottom edge of the screen")
        }
    }

    // MARK: - Actions & flow: floating buttons

    func testLayersButtonOpensSatellitePicker() throws {
        let app = reachMapScreen()

        element(app, id: A11yID.Map.layersButton).tap()

        // SatellitePickerSheet.swift sets this as its own NavigationView title - a
        // system-owned element, unlike this suite's usual accessibilityIdentifier
        // convention, but reliable since it's a literal English string in that file,
        // not something this suite adds.
        let title = app.navigationBars["Select Satellite Layer"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Satellite picker did not open after tapping the layers button")

        // "Default Imagery" (SatelliteOption.none's name) is always the first row
        // regardless of what imagery the current workspace defines - the one entry this
        // suite can rely on existing without depending on WorkspaceDetailsWithQuests
        // .json's own imagery list content.
        let defaultOption = app.buttons["Default Imagery"]
        XCTAssertTrue(defaultOption.waitForExistence(timeout: 5), "\"Default Imagery\" row not found in the satellite picker")
        defaultOption.tap()

        XCTAssertTrue(title.waitForNonExistence(timeout: 5), "Satellite picker did not close after selecting an option")
    }

    /// isBBoxValid (MapView.swift) rejects a visible area >= 3 km²; zooming out several
    /// times from the default zoom guarantees the visible area clears that regardless of
    /// what the default zoom happens to be.
    func testDownloadButtonShowsZoomInAlertWhenAreaTooLarge() throws {
        let app = reachMapScreen()

        let zoomOut = element(app, id: A11yID.Map.zoomOutButton)
        for _ in 0..<4 {
            zoomOut.tap()
        }

        element(app, id: A11yID.Map.downloadButton).tap()

        let alert = app.alerts["Zoom in to download data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Zoom-in-to-download alert did not appear for a too-large visible area")
        alert.buttons["OK"].tap()
    }

    /// The inverse of the above: zooming in to 22 (CustomMap's own hardcoded max, see
    /// the zoom-in button's `min(mapView.zoomLevel + 1.0, 22)`) guarantees a visible area
    /// far under the 3 km² threshold, so the download proceeds instead of showing the
    /// zoom-in alert. There's no positive on-screen signal for "the fetch happened" (the
    /// existing `map.json` stub already covers it regardless of bbox, per
    /// UITestStubs.swift's path-only match), so this only asserts the alert's absence.
    func testDownloadButtonFetchesDataWhenZoomedInEnough() throws {
        let app = reachMapScreen()

        let zoomIn = element(app, id: A11yID.Map.zoomInButton)
        for _ in 0..<8 {
            zoomIn.tap()
        }

        element(app, id: A11yID.Map.downloadButton).tap()

        let alert = app.alerts["Zoom in to download data"]
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "Zoom-in-to-download alert appeared despite an already-small visible area")
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).exists, "Left the Map screen after tapping download")
    }

    func testUndoButtonOpensSidebar() throws {
        let app = reachMapScreen()

        element(app, id: A11yID.Map.undoButton).tap()

        // The close button is the sidebar's presence signal, not a separate root
        // identifier - see this file's note on UndoSidebarView.swift for why.
        let close = element(app, id: A11yID.Map.undoSidebarCloseButton)
        XCTAssertTrue(close.waitForExistence(timeout: 5), "Undo sidebar did not open after tapping the undo button")
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 5), "Undo sidebar did not close after tapping its close button")
    }

    /// My Location's actual recenter effect isn't asserted - see this file's header
    /// comment for why (MapLibre's own user-location layer, independent of this app's
    /// mocked LocationManagerDelegate). This only confirms the tap is safe.
    func testMyLocationButtonRemainsUsableAfterTap() throws {
        let app = reachMapScreen()

        element(app, id: A11yID.Map.myLocationButton).tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 5),
                      "Left the Map screen after tapping My Location")
        XCTAssertTrue(element(app, id: A11yID.Map.myLocationButton).isHittable, "My Location button not usable after tapping it")
    }

    /// Zoom level itself isn't asserted - see this file's header comment for why (no
    /// on-screen text shows it anywhere). This only confirms repeated taps - including
    /// running past both the 0 floor and the 22 ceiling the app itself clamps to - stay
    /// safe and the buttons stay usable.
    func testZoomInAndOutButtonsRemainUsableAfterTapping() throws {
        let app = reachMapScreen()

        let zoomIn = element(app, id: A11yID.Map.zoomInButton)
        let zoomOut = element(app, id: A11yID.Map.zoomOutButton)

        for _ in 0..<10 { zoomIn.tap() }
        XCTAssertTrue(zoomIn.isHittable, "Zoom in button not usable after repeated taps up to its ceiling")

        for _ in 0..<20 { zoomOut.tap() }
        XCTAssertTrue(zoomOut.isHittable, "Zoom out button not usable after repeated taps down to its floor")

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).exists, "Left the Map screen after zooming")
    }

    // MARK: - Actions & flow: top bar

    /// The "has pending items" branch (real sync attempt) isn't covered - it needs
    /// seeding local pending changes plus new mocks for the changeset create/upload/
    /// close endpoints, neither of which exist yet. A freshly-launched scenario has
    /// nothing pending, so this is the one sync outcome reachable with zero new mocking.
    func testSyncButtonShowsNoElementsToSyncMessage() throws {
        let app = reachMapScreen()

        trailingToolbarButton(app, id: A11yID.Map.syncButton).tap()

        let status = element(app, id: A11yID.Map.syncStatusAlert)
        XCTAssertTrue(status.waitForExistence(timeout: 5), "Sync status message did not appear after tapping sync")
        XCTAssertTrue(status.label.contains("No elements to sync"),
                      "Sync status message was unexpected for a freshly-launched scenario - label was: \(status.label)")
    }

    func testAccessibilityModeButtonOpensScreenReaderMode() throws {
        let app = reachMapScreen()

        trailingToolbarButton(app, id: A11yID.Map.accessibilityModeButton, overflowMenuText: "Screen Reader Mode").tap()

        let close = element(app, id: A11yID.Map.accessibilityModeCloseButton)
        XCTAssertTrue(close.waitForExistence(timeout: 10), "Screen Reader Mode did not open after tapping its toolbar button")
        close.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 5),
                      "Did not return to the Map screen after closing Screen Reader Mode")
    }

    func testManageQuestsButtonOpensManageQuestsSheet() throws {
        let app = reachMapScreen()

        trailingToolbarButton(app, id: A11yID.Map.manageQuestsButton, overflowMenuText: "Manage Quests").tap()

        let close = element(app, id: A11yID.Map.manageQuestsCloseButton)
        XCTAssertTrue(close.waitForExistence(timeout: 10), "Manage Quests sheet did not open after tapping its toolbar button")
        close.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 5),
                      "Did not return to the Map screen after closing Manage Quests")
    }

    // MARK: - Actions & flow: map gestures

    /// A real XCUIElement `.tap()` on a QuestAnnotationView (a genuine MLNAnnotationView/
    /// UIView, not a SwiftUI shortcut) drives UIKit's normal hit-testing into MapLibre's
    /// own tap recognizer the same way a physical tap would, so this exercises the real
    /// `mapView(_:didSelect:)` selection path, not a test-only stand-in for it.
    func testTappingQuestAnnotationOpensQuestAnswerSheet() throws {
        let app = reachMapScreen()

        let quest = app.buttons.matching(identifier: A11yID.Map.questAnnotation).firstMatch
        XCTAssertTrue(quest.waitForExistence(timeout: 40), "No quest annotation appeared to tap")
        quest.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.questAnswerSheet).waitForExistence(timeout: 10),
                      "Quest answer sheet did not open after tapping a quest annotation")
    }

    /// Multi-select is entered exclusively by a long-press directly on an existing quest
    /// annotation (CustomMap.swift's handleLongPress, within 30pt of a non-cluster pin) -
    /// there is no separate mode-toggle control anywhere in the UI.
    func testLongPressingQuestAnnotationEntersMultiSelectMode() throws {
        let app = reachMapScreen()

        let quest = app.buttons.matching(identifier: A11yID.Map.questAnnotation).firstMatch
        XCTAssertTrue(quest.waitForExistence(timeout: 40), "No quest annotation appeared to long-press")
        quest.press(forDuration: 0.6)

        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10),
                      "Multi-select sheet did not appear after long-pressing a quest annotation")
    }

    /// See emptyMapPoint's own comment: this dataset is real and dense enough that empty
    /// screen space isn't guaranteed to exist even after zooming in, so the skip path
    /// here is expected to matter on some runs, not just a theoretical fallback.
    func testLongPressingEmptyMapAreaShowsPinChoiceCard() throws {
        let app = reachMapScreen()

        let zoomIn = element(app, id: A11yID.Map.zoomInButton)
        for _ in 0..<7 { zoomIn.tap() }

        // Clustering re-runs after a 0.2s debounce Timer plus a background grouping
        // pass on top of each zoom's own animated camera move (CustomMap.swift) -
        // scanning for annotation frames before that settles risks a stale/incomplete
        // list, which is worse than not scanning at all: a long-press aimed at what
        // looked like empty space could still land on a pin that finished moving there
        // after the scan.
        sleep(2)

        guard let point = emptyMapPoint(app) else {
            throw XCTSkip("No empty map point found on this dataset even after zooming all the way in")
        }
        longPress(app, at: point)

        // "Create Note" is the card's presence signal, not a separate root identifier -
        // see this file's note on PinChoiceCard for why.
        XCTAssertTrue(element(app, id: A11yID.Map.pinChoiceCreateNoteButton).waitForExistence(timeout: 5),
                      "Pin choice card (\"Create Note\" option) did not appear after long-pressing an empty map area")
        XCTAssertTrue(element(app, id: A11yID.Map.pinChoiceAddFeatureButton).exists, "\"Add Feature\" option missing from the pin choice card")
    }
}
