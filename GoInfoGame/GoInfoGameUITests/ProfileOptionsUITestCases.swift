//
//  ProfileOptionsUITestCases.swift
//  GoInfoGameUITests
//
//  The Profile screen's newer options (UserProfile/View/UserProfileView.swift), added after
//  ProfileScreenUITestCases was written, and the Show Quest Forms screen they lead to
//  (UserProfile/View/ShowQuestFormsView.swift):
//
//  - "Show map zoom buttons" (@AppStorage "showMapZoomButtons", default ON) - gates
//    MapView's zoom pill.
//  - "Keep screen on" (@AppStorage "keepScreenOn", default OFF) - the real effect is
//    UIApplication.isIdleTimerDisabled, which XCUITest cannot observe, so only the toggle's
//    state and persistence are covered here.
//  - Debug -> Show Quest Forms: lists the loaded workspace's long-form element types and
//    opens each as a preview LongForm (isPreviewMode: no ID/Name rows, no Compose Note or
//    Ignore). Nothing is submitted - Submit shows a "Tagging" alert of the tags that WOULD
//    be written.
//
//  Two entry points matter: opened from Workspaces (isWorkspaceSelected: false) the list is
//  always empty; opened from Map (true) it lists the workspace's element types. Map-based
//  tests use mapWithQuestClusters, whose workspace (WorkspaceDetailsWithQuests.json) has
//  Sidewalks, Crossings and Kerbs. Every test launches with reset state, so both
//  @AppStorage values start at their defaults.
//

import XCTest

final class ProfileOptionsUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        app.scrollViews[A11yID.Profile.scrollView]
    }

    @discardableResult
    private func reachProfileFromWorkspaces(file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 20),
                      "Did not land on the Workspaces screen", file: file, line: line)
        app.buttons[A11yID.Workspaces.profileButton].tap()
        XCTAssertTrue(element(app, id: A11yID.Profile.titleLabel).waitForExistence(timeout: 10),
                      "Did not land on the Profile screen", file: file, line: line)
        return app
    }

    private func openProfileFromMap(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        // The toolbar item exposes this identifier on both a wrapper and the button itself;
        // `app.buttons` picks the real button (same as MapScreenUITestCases).
        let profileButton = app.buttons[A11yID.Map.profileButton]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 10), "Map profile button not found", file: file, line: line)
        profileButton.tap()
        XCTAssertTrue(element(app, id: A11yID.Profile.nameAndEmailLabel).waitForExistence(timeout: 10),
                      "Did not land on the Profile screen", file: file, line: line)
    }

    @discardableResult
    private func reachProfileFromMap(file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        openProfileFromMap(app, file: file, line: line)
        return app
    }

    private func backToMap(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        app.buttons[A11yID.Profile.backButton].tap()
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Did not return to the Map screen", file: file, line: line)
    }

    /// SwiftUI's Toggle spans the whole row, and a center tap lands on its label rather than
    /// the switch - the trailing edge is where the switch actually is.
    private func tapToggle(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }

    private func isOn(_ toggle: XCUIElement) -> Bool {
        (toggle.value as? String) == "1"
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            usleep(300_000)
        } while Date() < deadline
        return condition()
    }

    private func openShowQuestForms(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let row = element(app, id: A11yID.Profile.showQuestFormsRow)
        XCTAssertTrue(scrollToElement(row, in: scroll(in: app)), "Show Quest Forms row unreachable", file: file, line: line)
        row.tap()
        XCTAssertTrue(app.buttons[A11yID.ShowQuestForms.backButton].waitForExistence(timeout: 10),
                      "Did not land on the Show Quest Forms screen", file: file, line: line)
    }

    /// Mirrors LongFormScreenUITestCases' own copy of this helper (not visible across files),
    /// including the half-span swipe - a full-screen swipe can jump clean over a short
    /// question in this lazy list and never recover (see MultiQuestSelectionUITestCases).
    @discardableResult
    private func scrollFormToElement(_ element: XCUIElement, maxSwipes: Int = 16) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        let x: CGFloat = 15
        let half = (window.height - 48) / 4
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            let down = !(element.exists && element.frame.midY < window.midY)
            let (fromY, toY) = down ? (window.midY + half, window.midY - half)
                                    : (window.midY - half, window.midY + half)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: fromY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: toY))
            start.press(forDuration: 0.05, thenDragTo: end)
            swipes += 1
        }
        return element.exists && element.isHittable
    }

    private func dismissKeyboardIfShown(_ app: XCUIApplication) {
        let done = app.toolbars.buttons["Done"]
        if done.exists {
            done.tap()
            return
        }
        guard app.keyboards.count > 0 else { return }
        let list = element(app, id: A11yID.LongForm.scrollView)
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 15, dy: list.frame.minY + 24))
            .tap()
    }

    // MARK: - Show map zoom buttons

    func testZoomButtonsToggleDefaultsOnAndKeepScreenOnDefaultsOff() throws {
        let app = reachProfileFromWorkspaces()

        let zoom = element(app, id: A11yID.Profile.showMapZoomButtonsToggle)
        let keepOn = element(app, id: A11yID.Profile.keepScreenOnToggle)
        XCTAssertTrue(scrollToElement(zoom, in: scroll(in: app)), "Show map zoom buttons toggle unreachable")
        XCTAssertTrue(scrollToElement(keepOn, in: scroll(in: app)), "Keep screen on toggle unreachable")

        XCTAssertTrue(isOn(zoom), "Show map zoom buttons should default to ON - value: \(String(describing: zoom.value))")
        XCTAssertFalse(isOn(keepOn), "Keep screen on should default to OFF - value: \(String(describing: keepOn.value))")
    }

    func testZoomButtonsToggleFlipsAndPersistsAfterLeavingAndReturning() throws {
        let app = reachProfileFromWorkspaces()

        let toggle = element(app, id: A11yID.Profile.showMapZoomButtonsToggle)
        XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "Toggle unreachable")
        tapToggle(toggle)
        XCTAssertTrue(waitUntil(timeout: 3, condition: { !isOn(toggle) }), "Toggle did not switch off")

        app.buttons[A11yID.Profile.backButton].tap()
        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 10), "Did not return to Workspaces")
        app.buttons[A11yID.Workspaces.profileButton].tap()
        XCTAssertTrue(element(app, id: A11yID.Profile.titleLabel).waitForExistence(timeout: 10), "Did not return to Profile")

        let reopened = element(app, id: A11yID.Profile.showMapZoomButtonsToggle)
        XCTAssertTrue(scrollToElement(reopened, in: scroll(in: app)), "Toggle unreachable on return")
        XCTAssertFalse(isOn(reopened), "Setting was not remembered after leaving and returning")
    }

    /// The setting's actual consumer: MapView only renders its zoom pill while it is on.
    func testTurningOffZoomButtonsHidesThemOnMapAndTurningOnRestoresThem() throws {
        let app = launchApp(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen")
        XCTAssertTrue(element(app, id: A11yID.Map.zoomInButton).exists, "Zoom In missing at the default setting")
        XCTAssertTrue(element(app, id: A11yID.Map.zoomOutButton).exists, "Zoom Out missing at the default setting")

        openProfileFromMap(app)
        let toggle = element(app, id: A11yID.Profile.showMapZoomButtonsToggle)
        XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "Toggle unreachable")
        tapToggle(toggle)
        XCTAssertTrue(waitUntil(timeout: 3, condition: { !isOn(toggle) }), "Toggle did not switch off")
        backToMap(app)

        XCTAssertTrue(element(app, id: A11yID.Map.zoomInButton).waitForNonExistence(timeout: 5),
                      "Zoom In still showing with the setting off")
        XCTAssertTrue(element(app, id: A11yID.Map.zoomOutButton).waitForNonExistence(timeout: 5),
                      "Zoom Out still showing with the setting off")
        // Only the zoom pill is gated - the rest of the floating controls must be untouched.
        XCTAssertTrue(element(app, id: A11yID.Map.myLocationButton).exists, "My Location button disappeared too")
        XCTAssertTrue(element(app, id: A11yID.Map.layersButton).exists, "Layers button disappeared too")

        openProfileFromMap(app)
        let again = element(app, id: A11yID.Profile.showMapZoomButtonsToggle)
        XCTAssertTrue(scrollToElement(again, in: scroll(in: app)), "Toggle unreachable the second time")
        tapToggle(again)
        XCTAssertTrue(waitUntil(timeout: 3, condition: { isOn(again) }), "Toggle did not switch back on")
        backToMap(app)

        XCTAssertTrue(element(app, id: A11yID.Map.zoomInButton).waitForExistence(timeout: 5), "Zoom In did not come back")
        XCTAssertTrue(element(app, id: A11yID.Map.zoomOutButton).exists, "Zoom Out did not come back")
    }

    // MARK: - Keep screen on

    func testKeepScreenOnToggleFlipsAndPersistsAfterLeavingAndReturning() throws {
        let app = reachProfileFromWorkspaces()

        let toggle = element(app, id: A11yID.Profile.keepScreenOnToggle)
        XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "Toggle unreachable")
        tapToggle(toggle)
        XCTAssertTrue(waitUntil(timeout: 3, condition: { isOn(toggle) }), "Toggle did not switch on")

        app.buttons[A11yID.Profile.backButton].tap()
        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 10), "Did not return to Workspaces")
        app.buttons[A11yID.Workspaces.profileButton].tap()
        XCTAssertTrue(element(app, id: A11yID.Profile.titleLabel).waitForExistence(timeout: 10), "Did not return to Profile")

        let reopened = element(app, id: A11yID.Profile.keepScreenOnToggle)
        XCTAssertTrue(scrollToElement(reopened, in: scroll(in: app)), "Toggle unreachable on return")
        XCTAssertTrue(isOn(reopened), "Setting was not remembered after leaving and returning")

        tapToggle(reopened)
        XCTAssertTrue(waitUntil(timeout: 3, condition: { !isOn(reopened) }), "Toggle did not switch back off")
    }

    /// The two new toggles are independent of each other and of low bandwidth mode.
    func testPreferenceTogglesAreIndependent() throws {
        let app = reachProfileFromWorkspaces()
        let zoom = element(app, id: A11yID.Profile.showMapZoomButtonsToggle)
        let keepOn = element(app, id: A11yID.Profile.keepScreenOnToggle)
        let lowBandwidth = element(app, id: A11yID.Profile.lowBandwidthToggle)
        for (toggle, name) in [(lowBandwidth, "Low bandwidth"), (zoom, "Zoom buttons"), (keepOn, "Keep screen on")] {
            XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "\(name) toggle unreachable")
        }
        let lowBefore = lowBandwidth.value as? String

        tapToggle(keepOn)
        XCTAssertTrue(waitUntil(timeout: 3, condition: { isOn(keepOn) }), "Keep screen on did not switch on")

        XCTAssertTrue(isOn(zoom), "Flipping Keep screen on changed Show map zoom buttons")
        XCTAssertEqual(lowBandwidth.value as? String, lowBefore, "Flipping Keep screen on changed Low bandwidth mode")
    }

    // MARK: - Show Quest Forms: list

    func testShowQuestFormsFromWorkspacesIsEmptyBecauseNoWorkspaceIsLoaded() throws {
        let app = reachProfileFromWorkspaces()
        openShowQuestForms(app)

        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.nothingFoundMessage).waitForExistence(timeout: 5),
                      "Expected \"Nothing found\" when Profile is opened before any workspace is loaded")
        XCTAssertFalse(element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks")).exists,
                       "A form row is listed even though no workspace is selected")
    }

    func testShowQuestFormsFromMapListsWorkspaceElementTypes() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)

        for type in ["Sidewalks", "Crossings", "Kerbs"] {
            XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: type)).waitForExistence(timeout: 10),
                          "\(type) not listed")
        }
        XCTAssertFalse(element(app, id: A11yID.ShowQuestForms.nothingFoundMessage).exists,
                       "\"Nothing found\" shown alongside a populated list")
    }

    func testShowQuestFormsSearchFiltersTheListCaseInsensitively() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)
        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks")).waitForExistence(timeout: 10),
                      "List did not load")

        let search = app.searchFields.firstMatch
        if !search.waitForExistence(timeout: 3) {
            // `.navigationBarDrawer(displayMode: .automatic)` tucks the field away until the
            // list is pulled down.
            let row = element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks"))
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 5)))
        }
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Search field not found")
        search.tap()
        search.typeText("kErB")

        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: "Kerbs")).waitForExistence(timeout: 5),
                      "Kerbs missing after searching \"kErB\"")
        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks")).waitForNonExistence(timeout: 5),
                      "Sidewalks still listed after searching \"kErB\"")
        XCTAssertFalse(element(app, id: A11yID.ShowQuestForms.row(elementType: "Crossings")).exists,
                       "Crossings still listed after searching \"kErB\"")
    }

    func testShowQuestFormsSearchWithNoMatchShowsNothingFound() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)
        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks")).waitForExistence(timeout: 10),
                      "List did not load")

        let search = app.searchFields.firstMatch
        if !search.waitForExistence(timeout: 3) {
            let row = element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks"))
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 5)))
        }
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Search field not found")
        search.tap()
        search.typeText("zzzz")

        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.nothingFoundMessage).waitForExistence(timeout: 5),
                      "\"Nothing found\" not shown for a search with no matches")
    }

    func testShowQuestFormsBackButtonReturnsToProfile() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)

        app.buttons[A11yID.ShowQuestForms.backButton].tap()

        XCTAssertTrue(element(app, id: A11yID.Profile.titleLabel).waitForExistence(timeout: 10),
                      "Did not return to the Profile screen")
        XCTAssertTrue(app.buttons[A11yID.ShowQuestForms.backButton].waitForNonExistence(timeout: 5),
                      "Still on Show Quest Forms after tapping back")
    }

    // MARK: - Show Quest Forms: preview form

    func testOpeningAFormShowsPreviewWithoutNoteOrIgnoreControls() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)

        let row = element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks"))
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Sidewalks not listed")
        row.tap()

        XCTAssertTrue(element(app, id: A11yID.LongForm.dismissButton).waitForExistence(timeout: 15),
                      "Preview form did not open")
        // Preview mode hides the element-specific rows - there is no element to compose a
        // note about or to ignore.
        XCTAssertFalse(element(app, id: A11yID.LongForm.composeNoteButton).exists, "Compose Note shown in preview mode")
        XCTAssertFalse(element(app, id: A11yID.LongForm.ignoreQuestButton).exists, "Ignore shown in preview mode")
        XCTAssertTrue(element(app, id: A11yID.LongForm.question(questID: 101)).waitForExistence(timeout: 5)
                      || scrollFormToElement(element(app, id: A11yID.LongForm.question(questID: 101))),
                      "The form's questions did not load")
    }

    func testClosingThePreviewFormReturnsToTheList() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)

        let row = element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks"))
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Sidewalks not listed")
        row.tap()
        let dismiss = element(app, id: A11yID.LongForm.dismissButton)
        XCTAssertTrue(dismiss.waitForExistence(timeout: 15), "Preview form did not open")

        dismiss.tap()

        XCTAssertTrue(dismiss.waitForNonExistence(timeout: 10), "Preview form still showing after dismissing it")
        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks")).waitForExistence(timeout: 10),
                      "Did not return to the list")
        XCTAssertFalse(app.alerts[L10nText.tagging].exists, "A Tagging alert appeared though nothing was submitted")
    }

    /// The feature's whole point: Submit writes nothing, it only reports the tags that
    /// would be written - the same ADD "key"="value" form Android shows.
    func testSubmittingAPreviewFormShowsTheTagsItWouldWrite() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)

        let row = element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks"))
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Sidewalks not listed")
        row.tap()
        XCTAssertTrue(element(app, id: A11yID.LongForm.dismissButton).waitForExistence(timeout: 15), "Preview form did not open")

        // Fully answer every applicable Sidewalks question, in the form's own top-to-bottom
        // order (WorkspaceDetailsWithQuests.json: 107, 106, 101, 103, 104).
        let textEntry = element(app, id: A11yID.LongForm.textInput(questID: 107))
        XCTAssertTrue(scrollFormToElement(textEntry), "Quest 107 text entry not reachable")
        textEntry.tap()
        textEntry.typeText("Preview note")
        dismissKeyboardIfShown(app)

        let choice1 = element(app, id: A11yID.LongForm.option(questID: 106, value: "choice_1"))
        XCTAssertTrue(scrollFormToElement(choice1), "Quest 106 choice_1 not reachable")
        choice1.tap()

        let concrete = element(app, id: A11yID.LongForm.option(questID: 101, value: "concrete"))
        XCTAssertTrue(scrollFormToElement(concrete), "Surface option not reachable")
        concrete.tap()

        let width = element(app, id: A11yID.LongForm.numericInput(questID: 103))
        XCTAssertTrue(scrollFormToElement(width), "Width field not reachable")
        width.tap()
        width.typeText("40")
        dismissKeyboardIfShown(app)

        let obstructionNo = element(app, id: A11yID.LongForm.option(questID: 104, value: "no"))
        XCTAssertTrue(scrollFormToElement(obstructionNo), "Obstruction option not reachable")
        obstructionNo.tap()

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit), "Submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Submit disabled despite every applicable question being answered")
        submit.tap()

        // The alert is deliberately held back until the sheet has finished dismissing.
        let alert = app.alerts[L10nText.tagging]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Tagging alert did not appear after submitting the preview")
        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "ADD \"ext:surface\"=\"concrete\"")).firstMatch.exists,
                      "Alert does not list the surface tag - alert: \(alert.debugDescription)")
        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "ADD \"width\"=\"40\"")).firstMatch.exists,
                      "Alert does not list the width tag - alert: \(alert.debugDescription)")

        alert.buttons[L10nText.ok].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "Alert still showing after OK")
        XCTAssertTrue(element(app, id: A11yID.ShowQuestForms.row(elementType: "Sidewalks")).waitForExistence(timeout: 10),
                      "Did not return to the list after dismissing the alert")
        // A preview must never queue anything for sync.
        XCTAssertTrue(app.buttons[A11yID.ShowQuestForms.backButton].exists)
        app.buttons[A11yID.ShowQuestForms.backButton].tap()
        app.buttons[A11yID.Profile.backButton].tap()
        let sync = element(app, id: A11yID.Map.syncButton)
        XCTAssertTrue(sync.waitForExistence(timeout: 10), "Did not return to the Map screen")
        XCTAssertFalse((sync.value as? String ?? "").contains("pending"),
                       "A previewed submission was queued for sync - value: \(String(describing: sync.value))")
    }

    // MARK: - Layout

    func testNewProfileOptionsAreReachableTappableAndDoNotOverlap() throws {
        let app = reachProfileFromWorkspaces()
        let scrollView = scroll(in: app)
        let window = app.windows.firstMatch.frame

        let controls: [(XCUIElement, String)] = [
            (element(app, id: A11yID.Profile.lowBandwidthToggle), "Low bandwidth toggle"),
            (element(app, id: A11yID.Profile.showMapZoomButtonsToggle), "Show map zoom buttons toggle"),
            (element(app, id: A11yID.Profile.keepScreenOnToggle), "Keep screen on toggle"),
            (element(app, id: A11yID.Profile.showQuestFormsRow), "Show Quest Forms row"),
            (app.buttons[A11yID.Profile.logoutButton], "Logout button")
        ]
        for (control, name) in controls {
            XCTAssertTrue(scrollToElement(control, in: scrollView), "\(name) unreachable")
            XCTAssertGreaterThanOrEqual(control.frame.height, 35.0, "\(name) is shorter than the minimum tap target")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.minX, "\(name) extends past the left edge")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.maxX, "\(name) extends past the right edge")
        }
        assertNoOverlap(controls.map { ($0.0, $0.1) })
    }

    func testShowQuestFormsScreenLayout() throws {
        let app = reachProfileFromMap()
        openShowQuestForms(app)

        let back = app.buttons[A11yID.ShowQuestForms.backButton]
        let rows = ["Sidewalks", "Crossings", "Kerbs"].map {
            (element(app, id: A11yID.ShowQuestForms.row(elementType: $0)), "\($0) row")
        }
        XCTAssertTrue(rows[0].0.waitForExistence(timeout: 10), "List did not load")

        let window = app.windows.firstMatch.frame
        for (control, name) in [(back, "Back button")] + rows {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
            XCTAssertGreaterThanOrEqual(control.frame.height, 35.0, "\(name) is shorter than the minimum tap target")
        }
        assertNoOverlap([(back, "Back button")] + rows)
    }
}

/// Fixed English strings of the native alert, matched by text like every other alert in
/// this suite - an alert's buttons and title have no identifier hook.
private enum L10nText {
    static let tagging = "Tagging"
    static let ok = "OK"
}
