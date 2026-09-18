//
//  WorkspacesScreenUITestCases.swift
//  GoInfoGameUITests
//
//  The Workspaces screen (InitialView / WorkspacesListView) shown right after login.
//
//  Every scenario here skips the login screen's own UI: UITestStubs.installIfNeeded()
//  seeds `loggedIn = true` plus a valid-shaped accessToken directly (see
//  seedLoggedInAndLandOnWorkspaces() in UITestStubs.swift), which is all SceneDelegate
//  needs to choose InitialView as the root at launch. Faster than re-driving the login
//  form in every test, and keeps this suite from depending on the login screen's UI.
//
//  WorkspacesList.json is a real captured API response (119 workspaces), but only those
//  with type == "osw" && externalAppAccess == 1 are "eligible" (InitialViewModel
//  .eligibleWorkspaces) - everything else is filtered out before the screen ever shows it,
//  including from search/filter. Only 7 of the 119 qualify, split across 2 of the 3 groups
//  in ProjectGroupRoles.json:
//    "AA Viewer Internal"    (1ec1c79b-...): 186, 187, 222, 1765, 1857
//    "Asian Leisure Pvt Ltd" (1bfb55d7-...): 1758, 1595
//    "TDEI Default"          (a9647ce1-...): none eligible - never appears in the filter
//  Tests that reference these ids/titles/group names are tied to that fixture content by
//  design - update both together if the captured data changes.
//
//  WorkspaceDetailsSingle.json (id 222, paired with WorkspacesSingle.json for the
//  single-eligible-workspace scenario) has longFormQuestDef: null in the captured
//  response. InitialViewModel.fetchLongQuestsFor treats a nil longFormQuest as a failure
//  ("Please configure longform."), which - traced through WorkspacesListView's branching -
//  does NOT auto-navigate to MapView; it falls back to the normal picker UI showing that
//  one workspace as an ordinary row. That is real, current backend behavior for this
//  workspace, not a fixture mistake, so the test below verifies the fallback rather than
//  the redirect. Testing an actual auto-redirect would need a captured (or reconstructed)
//  response where longFormQuestDef is populated instead of null.
//

import XCTest

final class WorkspacesScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        app.scrollViews[A11yID.Workspaces.scrollView]
    }

    private func waitForWorkspacesScreen(_ app: XCUIApplication,
                                         file: StaticString = #filePath,
                                         line: UInt = #line) {
        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 20),
                      "Did not land on the Workspaces screen", file: file, line: line)
    }

    private func activateSearch(_ app: XCUIApplication,
                                text: String,
                                file: StaticString = #filePath,
                                line: UInt = #line) {
        let toggle = app.buttons[A11yID.Workspaces.searchToggleButton]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Search toggle button not found", file: file, line: line)
        toggle.tap()

        let field = app.textFields[A11yID.Workspaces.searchField]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Search field did not appear", file: file, line: line)
        field.tap()
        dismissSystemAlertsIfPresent(app)
        field.tap()
        field.typeText(text)
    }

    private func workspaceRow(_ app: XCUIApplication, id: Int) -> XCUIElement {
        app.buttons[A11yID.Workspaces.workspaceRow(id: id)]
    }

    // MARK: - Content states

    func testWorkspacesScreenShowsExpectedElementsAfterSuccessfulLogin() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        XCTAssertTrue(app.buttons[A11yID.Workspaces.profileButton].exists, "Profile button not found")
        XCTAssertTrue(app.buttons[A11yID.Workspaces.searchToggleButton].exists, "Search toggle button not found")

        for id in [186, 187, 222, 1765, 1857, 1758, 1595] {
            XCTAssertTrue(scrollToElement(workspaceRow(app, id: id), in: scroll(in: app)),
                          "Workspace row \(id) not reachable")
        }
    }

    func testEmptyWorkspacesShowsEmptyMessage() throws {
        let app = launchApp(scenario: UITestScenario.workspacesEmpty)
        waitForWorkspacesScreen(app)

        let emptyText = app.staticTexts[A11yID.Workspaces.emptyText]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 15), "Empty-workspaces message did not appear")
        XCTAssertFalse(workspaceRow(app, id: 186).exists, "A workspace row rendered despite an empty list")
    }

    func testWorkspacesFetchServerErrorShowsErrorAndTryAgain() throws {
        let app = launchApp(scenario: UITestScenario.workspacesServerError)
        waitForWorkspacesScreen(app)

        let errorText = app.staticTexts[A11yID.Workspaces.errorText]
        XCTAssertTrue(errorText.waitForExistence(timeout: 15), "Error message did not appear after a 500")

        let tryAgain = element(app, id: A11yID.Workspaces.tryAgainButton)
        XCTAssertTrue(tryAgain.waitForExistence(timeout: 5), "Try again button not found")
        XCTAssertTrue(scrollToElement(tryAgain, in: scroll(in: app)), "Try again button unreachable")
    }

    /// This app has no dedicated offline UI (confirmed: NetworkMonitor/NetworkManager are
    /// wired only into ForceUpdateManager, nowhere near workspace fetching) - a
    /// connectivity failure surfaces through the exact same generic error branch as a
    /// server error. This test exists specifically to pin that down, not to describe a
    /// distinct "offline" screen that does not exist.
    func testWorkspacesFetchNetworkDownSharesTheSameErrorUIAsAServerError() throws {
        let app = launchApp(scenario: UITestScenario.workspacesNetworkDown)
        waitForWorkspacesScreen(app)

        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.errorText].waitForExistence(timeout: 15),
                      "Error message did not appear after a connectivity failure")
        XCTAssertTrue(element(app, id: A11yID.Workspaces.tryAgainButton).waitForExistence(timeout: 5),
                      "Try again button not found after a connectivity failure")
    }

    /// Exactly 1 eligible workspace (id 222), whose captured details response has
    /// longFormQuestDef: null. InitialViewModel.fetchLongQuestsFor treats that as a
    /// failure ("Please configure longform."), which sets autoRedirectToMapViewError and
    /// - per WorkspacesListView's branching - makes the screen fall back to the ordinary
    /// picker UI showing that one workspace as a normal row, rather than navigating to
    /// MapView or getting stuck. This is real backend behavior for this workspace, not a
    /// fixture mistake (see the file-level comment), so this test verifies the fallback.
    func testSingleEligibleWorkspaceWithoutLongformFallsBackToPicker() throws {
        let app = launchApp(scenario: UITestScenario.workspacesSingleAutoRedirect)
        waitForWorkspacesScreen(app)

        XCTAssertTrue(scrollToElement(workspaceRow(app, id: 222), in: scroll(in: app)),
                      "The single eligible workspace did not appear as a picker row")
        // Confirms this is genuinely the fallback path (a title/row on the normal picker
        // screen), not a coincidental element left over from a screen that partially
        // failed to load.
        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].exists,
                      "Workspaces title gone - screen may have navigated instead of falling back")
    }

    // MARK: - Search

    func testSearchFiltersWorkspacesByTitle() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        // "Bugs Testing Workspace" (1857) is the only eligible title containing this -
        // verified against the captured fixture, no other eligible entry matches it.
        activateSearch(app, text: "Bugs Testing")

        XCTAssertTrue(scrollToElement(workspaceRow(app, id: 1857), in: scroll(in: app)),
                      "Matching workspace (Bugs Testing Workspace) not shown for a matching search")
        for id in [186, 187, 222, 1765, 1758, 1595] {
            XCTAssertFalse(workspaceRow(app, id: id).exists, "Non-matching workspace \(id) still shown during search")
        }
    }

    func testSearchWithNoMatchesShowsNoResultsAndClearFiltersRestoresList() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        activateSearch(app, text: "no workspace has this in its title")

        let noResults = app.staticTexts[A11yID.Workspaces.noResultsText]
        XCTAssertTrue(noResults.waitForExistence(timeout: 5), "No-results message did not appear")

        let clearFilters = element(app, id: A11yID.Workspaces.clearFiltersButton)
        XCTAssertTrue(clearFilters.waitForExistence(timeout: 5), "Clear filters button not found")
        clearFilters.tap()

        XCTAssertTrue(scrollToElement(workspaceRow(app, id: 186), in: scroll(in: app)),
                      "Full workspace list did not return after clearing filters")
        XCTAssertFalse(noResults.exists, "No-results message still shown after clearing filters")
    }

    func testSearchClearButtonRestoresFullList() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        activateSearch(app, text: "Bugs Testing")
        XCTAssertFalse(workspaceRow(app, id: 186).exists, "Search did not filter the list before clearing it")

        let clear = app.buttons[A11yID.Workspaces.searchClearButton]
        XCTAssertTrue(clear.waitForExistence(timeout: 5), "Search clear (x) button not found")
        clear.tap()

        XCTAssertTrue(scrollToElement(workspaceRow(app, id: 186), in: scroll(in: app)),
                      "Full workspace list did not return after clearing the search text")
    }

    // MARK: - Filter

    func testFilterByProjectGroupShowsOnlyMatchingWorkspaces() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        let filter = element(app, id: A11yID.Workspaces.projectGroupFilter)
        XCTAssertTrue(filter.waitForExistence(timeout: 10), "Project group filter not found")
        XCTAssertTrue(scrollToElement(filter, in: scroll(in: app)), "Project group filter unreachable")
        filter.tap()

        // Matches ProjectGroupRoles.json exactly - not localized, so safe to match by text
        // (same reasoning as the login screen's environment menu options). "TDEI Default"
        // is deliberately not checked as selectable here: it has zero eligible workspaces
        // in the captured WorkspacesList.json, so projectGroupIds (built only from
        // eligible workspaces) never includes it - the next assertion confirms that.
        XCTAssertFalse(app.buttons["TDEI Default"].exists,
                       "A project group with no eligible workspaces appeared in the filter menu")

        let asianLeisure = app.buttons["Asian Leisure Pvt Ltd"]
        XCTAssertTrue(asianLeisure.waitForExistence(timeout: 5), "\"Asian Leisure Pvt Ltd\" option missing from the filter menu")
        asianLeisure.tap()

        XCTAssertTrue(scrollToElement(workspaceRow(app, id: 1758), in: scroll(in: app)),
                      "Asian Leisure Pvt Ltd workspace not shown after filtering to its project group")
        XCTAssertTrue(workspaceRow(app, id: 1595).exists, "Asian Leisure Pvt Ltd workspace not shown after filtering")
        for id in [186, 187, 222, 1765, 1857] {
            XCTAssertFalse(workspaceRow(app, id: id).exists,
                           "AA Viewer Internal workspace \(id) still shown after filtering to Asian Leisure Pvt Ltd")
        }

        filter.tap()
        let allGroups = app.buttons["All Project Groups"]
        XCTAssertTrue(allGroups.waitForExistence(timeout: 5), "\"All Project Groups\" option missing from the filter menu")
        allGroups.tap()

        XCTAssertTrue(scrollToElement(workspaceRow(app, id: 186), in: scroll(in: app)),
                      "Full list did not return after selecting All Project Groups")
    }

    // MARK: - Profile navigation

    func testNavigatingToProfileScreenFromWorkspaces() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        let profileButton = app.buttons[A11yID.Workspaces.profileButton]
        XCTAssertTrue(scrollToElement(profileButton, in: scroll(in: app)), "Profile button unreachable")

        // waitForWorkspacesScreen(app) above already proved the title exists, before the
        // tap - a NavigationLink's push is a local UI transition (fetchUserProfile() in
        // UserProfileView's onAppear fires after the push, not before it), so the title
        // can legitimately already be gone by the time any check after tap() runs.
        // Re-checking waitForExistence here would be asking "does it exist right now",
        // which can go either way depending on how fast navigation happened, and is not
        // actually what this test means to verify - only waitForNonExistence, which
        // tolerates that timing, does.
        profileButton.tap()

        let title = app.staticTexts[A11yID.Workspaces.title]
        XCTAssertTrue(title.waitForNonExistence(timeout: 10), "Still on the Workspaces screen after tapping profile")
    }

    // MARK: - Layout: overlap

    func testWorkspacesHeaderElementsDoNotOverlap() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        assertNoOverlap([
            (app.buttons[A11yID.Workspaces.profileButton], "Profile button"),
            (app.buttons[A11yID.Workspaces.searchToggleButton], "Search toggle button"),
            (app.staticTexts[A11yID.Workspaces.title], "Workspaces title")
        ])
    }

    func testWorkspaceRowsDoNotOverlapEachOther() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        let scrollView = scroll(in: app)
        let rows = [186, 187, 222, 1765, 1857, 1758, 1595].map { id in
            (workspaceRow(app, id: id), "Workspace row \(id)")
        }
        for (row, description) in rows {
            XCTAssertTrue(scrollToElement(row, in: scrollView), "\(description) unreachable")
        }
        assertNoOverlap(rows)
    }

    // MARK: - Layout: reachability, tap targets, screen bounds

    func testAllWorkspacesElementsReachableAndTappable() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        let scrollView = scroll(in: app)
        var targets: [(XCUIElement, String)] = [
            (app.buttons[A11yID.Workspaces.profileButton], "Profile button"),
            (app.buttons[A11yID.Workspaces.searchToggleButton], "Search toggle button"),
            (element(app, id: A11yID.Workspaces.projectGroupFilter), "Project group filter")
        ]
        for id in [186, 187, 222, 1765, 1857, 1758, 1595] {
            targets.append((workspaceRow(app, id: id), "Workspace row \(id)"))
        }

        for (target, description) in targets {
            XCTAssertTrue(target.waitForExistence(timeout: 10), "\(description) not found")
            XCTAssertTrue(scrollToElement(target, in: scrollView), "\(description) could not be scrolled into view")
            XCTAssertGreaterThanOrEqual(target.frame.height, Self.minimumTapTarget,
                                        "\(description) is shorter than the 44pt minimum tap target")
            XCTAssertGreaterThanOrEqual(target.frame.width, Self.minimumTapTarget,
                                        "\(description) is narrower than the 44pt minimum tap target")
        }
    }

    func testWorkspacesElementsFitWithinScreenWidth() throws {
        let app = launchApp(scenario: UITestScenario.workspacesWithData)
        waitForWorkspacesScreen(app)

        let window = app.windows.firstMatch
        let scrollView = scroll(in: app)
        var controls: [(String, XCUIElement)] = [
            ("Workspaces title", app.staticTexts[A11yID.Workspaces.title]),
            ("Profile button", app.buttons[A11yID.Workspaces.profileButton]),
            ("Search toggle button", app.buttons[A11yID.Workspaces.searchToggleButton])
        ]
        for id in [186, 187, 222, 1765, 1857, 1758, 1595] {
            controls.append(("Workspace row \(id)", workspaceRow(app, id: id)))
        }

        for (description, control) in controls {
            XCTAssertTrue(control.waitForExistence(timeout: 10), "\(description) not found")
            XCTAssertTrue(scrollToElement(control, in: scrollView), "\(description) could not be scrolled into view")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX,
                                        "\(description) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX,
                                     "\(description) extends past the right edge of the screen")
        }
    }
}
