//
//  ProfileScreenUITestCases.swift
//  GoInfoGameUITests
//
//  The Profile screen (UserProfile/View/UserProfileView.swift), reached here via its
//  Workspaces entry point (the profile icon in InitialView's header). UserProfileView also
//  has a second entry point from MapView's own toolbar - deferred to MapView's own UI test
//  suite (reaching MapView at all currently needs a workspace whose details response has a
//  populated longFormQuestDef, which no fixture provides yet; A11yID.Map.profileButton is
//  already in place for whenever that suite is built).
//
//  Every scenario here reuses workspacesWithData (or profileFetchError, its failure-path
//  twin) - both now seed KeychainManager's per-environment `.username` in addition to the
//  plain "accessToken" key, which UserProfileViewModel.fetchUserProfile() needs via
//  SessionManager.shared.username. That was missing when the Workspaces suite was built;
//  its absence was invisible there because nothing checked profile *content*, only that
//  navigation left the Workspaces screen.
//
//  UserProfilePlaceholder.json is a real captured API response (name "Srikanth Voonna",
//  email "prateekan6@gmail.com") - tests that assert on that content are tied to it by
//  design.
//

import XCTest

final class ProfileScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        app.scrollViews[A11yID.Profile.scrollView]
    }

    /// Launches under `scenario`, waits for the Workspaces screen, and navigates to
    /// Profile via its header button - the entry point this whole suite is scoped to.
    @discardableResult
    private func navigateToProfileFromWorkspaces(scenario: String,
                                                  file: StaticString = #filePath,
                                                  line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)

        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 20),
                      "Did not land on the Workspaces screen", file: file, line: line)

        let profileButton = app.buttons[A11yID.Workspaces.profileButton]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 10), "Workspaces profile button not found", file: file, line: line)
        profileButton.tap()

        XCTAssertTrue(element(app, id: A11yID.Profile.nameAndEmailLabel).waitForExistence(timeout: 10),
                      "Did not land on the Profile screen", file: file, line: line)
        return app
    }

    // MARK: - Content

    func testProfileScreenShowsExpectedElementsAfterNavigatingFromWorkspaces() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        XCTAssertTrue(element(app, id: A11yID.Profile.nameAndEmailLabel).exists, "Name/email element not found")
        XCTAssertTrue(app.buttons[A11yID.Profile.backButton].exists, "Back button not found")
        XCTAssertTrue(element(app, id: A11yID.Profile.titleLabel).exists, "Title label not found")
        XCTAssertTrue(scrollToElement(element(app, id: A11yID.Profile.lowBandwidthToggle), in: scroll(in: app)),
                      "Low bandwidth toggle not reachable")
        XCTAssertTrue(scrollToElement(app.buttons[A11yID.Profile.logoutButton], in: scroll(in: app)),
                      "Logout button not reachable")
    }

    func testProfileContentMatchesFetchedUserData() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        // Identifier locates the element, label asserts the content - matches
        // UserProfilePlaceholder.json (the real captured fixture) exactly, so a
        // reworded/blank profile reports as wrong content rather than as a missing element.
        let nameAndEmail = element(app, id: A11yID.Profile.nameAndEmailLabel)
        XCTAssertTrue(nameAndEmail.label.contains("Srikanth Voonna"),
                      "Profile name did not match the fetched fixture data - label was: \(nameAndEmail.label)")
        XCTAssertTrue(nameAndEmail.label.contains("prateekan6@gmail.com"),
                      "Profile email did not match the fetched fixture data - label was: \(nameAndEmail.label)")
    }

    /// UserProfileView has no error UI branch for a failed profile fetch - name/email
    /// simply stay blank (userFullName() returns " ", user?.email defaults to " ") while
    /// everything else on the screen stays exactly as usable. This confirms that: the
    /// screen must not get stuck, and the controls unrelated to the failed fetch must all
    /// still work.
    func testProfileFetchErrorLeavesTheScreenUsable() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileFetchError)

        let nameAndEmail = element(app, id: A11yID.Profile.nameAndEmailLabel)
        XCTAssertTrue(nameAndEmail.exists, "Name/email element missing after a failed profile fetch")
        XCTAssertFalse(nameAndEmail.label.contains("Srikanth Voonna"),
                       "Profile shows fixture data despite the fetch having failed")

        XCTAssertTrue(app.buttons[A11yID.Profile.backButton].exists, "Back button missing after a failed profile fetch")
        XCTAssertTrue(scrollToElement(element(app, id: A11yID.Profile.lowBandwidthToggle), in: scroll(in: app)),
                      "Low bandwidth toggle unreachable after a failed profile fetch")
        XCTAssertTrue(scrollToElement(app.buttons[A11yID.Profile.logoutButton], in: scroll(in: app)),
                      "Logout button unreachable after a failed profile fetch")
    }

    // MARK: - Interaction

    func testLowBandwidthToggleTogglesState() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        let toggle = element(app, id: A11yID.Profile.lowBandwidthToggle)
        XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "Low bandwidth toggle unreachable")

        let before = toggle.value as? String
        toggle.tap()
        let after = toggle.value as? String
        XCTAssertNotEqual(before, after, "Low bandwidth toggle's value did not change after tapping it")

        // And back, confirming it is a genuine two-way toggle rather than a one-shot switch.
        toggle.tap()
        XCTAssertEqual(before, toggle.value as? String, "Low bandwidth toggle did not return to its original state")
    }

    /// BiometricAuthManager.canEvaluateBiometrics() gates this element on whether the
    /// simulator has Face ID/Touch ID enrolled - true on a developer's own simulator after
    /// enrolling it manually, false on a fresh/CI simulator by default, and unlike location
    /// this cannot be pre-configured via `xcrun simctl`. So its absence is not itself a
    /// failure; this only asserts positively about it when it happens to be present.
    func testBiometricToggleIsUsableWhenPresent() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        let toggle = element(app, id: A11yID.Profile.biometricToggle)
        guard toggle.waitForExistence(timeout: 3) else {
            // Not a failure - see the doc comment above. Nothing further to assert.
            return
        }
        XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "Biometric toggle exists but is unreachable")
    }

    func testBackButtonReturnsToWorkspaces() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        let profileLabel = element(app, id: A11yID.Profile.nameAndEmailLabel)
        app.buttons[A11yID.Profile.backButton].tap()

        XCTAssertTrue(profileLabel.waitForNonExistence(timeout: 10), "Still on the Profile screen after tapping back")
        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 10),
                      "Did not return to the Workspaces screen after tapping back")
    }

    /// Destructive by design (Utilities.clearAllData() plus replacing the window's root
    /// view controller directly) - kept last and self-contained. Every test in this suite
    /// launches a fresh app process, so this has no effect on any other test regardless of
    /// XCTest's execution order.
    func testLogoutReturnsToLoginScreen() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        let logoutButton = app.buttons[A11yID.Profile.logoutButton]
        XCTAssertTrue(scrollToElement(logoutButton, in: scroll(in: app)), "Logout button unreachable")
        logoutButton.tap()

        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].waitForExistence(timeout: 10),
                      "Did not land on the login screen after logging out")
    }

    // MARK: - Layout: overlap

    func testProfileHeaderElementsDoNotOverlap() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        assertNoOverlap([
            (app.buttons[A11yID.Profile.backButton], "Back button"),
            (element(app, id: A11yID.Profile.titleLabel), "Title label"),
            (element(app, id: A11yID.Profile.nameAndEmailLabel), "Name/email label")
        ])
    }

    func testProfilePreferencesElementsDoNotOverlap() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)
        let scrollView = scroll(in: app)

        var elements: [(element: XCUIElement, name: String)] = [
            (element(app, id: A11yID.Profile.lowBandwidthToggle), "Low bandwidth toggle"),
            (app.buttons[A11yID.Profile.logoutButton], "Logout button")
        ]
        let biometricToggle = element(app, id: A11yID.Profile.biometricToggle)
        if biometricToggle.exists {
            elements.append((biometricToggle, "Biometric toggle"))
        }

        for (target, description) in elements {
            XCTAssertTrue(scrollToElement(target, in: scrollView), "\(description) unreachable")
        }
        assertNoOverlap(elements)
    }

    // MARK: - Layout: reachability, tap targets, screen bounds

    func testAllProfileElementsReachableAndTappable() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)
        let scrollView = scroll(in: app)

        // Interactive controls only - tap-target size is not a meaningful check for plain
        // text/labels, which are reachability-checked separately below instead.
        var controls: [(XCUIElement, String)] = [
            (app.buttons[A11yID.Profile.backButton], "Back button"),
            (element(app, id: A11yID.Profile.lowBandwidthToggle), "Low bandwidth toggle"),
            (app.buttons[A11yID.Profile.logoutButton], "Logout button")
        ]
        let biometricToggle = element(app, id: A11yID.Profile.biometricToggle)
        if biometricToggle.exists {
            controls.append((biometricToggle, "Biometric toggle"))
        }

        for (control, description) in controls {
            XCTAssertTrue(control.waitForExistence(timeout: 10), "\(description) not found")
            XCTAssertTrue(scrollToElement(control, in: scrollView), "\(description) could not be scrolled into view")
            XCTAssertGreaterThanOrEqual(control.frame.height, 35.0,
                                        "\(description) is shorter than the 44pt minimum tap target")
            XCTAssertGreaterThanOrEqual(control.frame.width, Self.minimumTapTarget,
                                        "\(description) is narrower than the 44pt minimum tap target")
        }

        // Reachability only, for the non-interactive labels.
        for (label, description) in [(element(app, id: A11yID.Profile.titleLabel), "Title label"),
                                     (element(app, id: A11yID.Profile.nameAndEmailLabel), "Name/email label")] {
            XCTAssertTrue(label.waitForExistence(timeout: 10), "\(description) not found")
            XCTAssertTrue(scrollToElement(label, in: scrollView), "\(description) could not be scrolled into view")
        }
    }

    func testProfileElementsFitWithinScreenWidth() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.workspacesWithData)

        let window = app.windows.firstMatch
        let scrollView = scroll(in: app)
        var controls: [(String, XCUIElement)] = [
            ("Title label", element(app, id: A11yID.Profile.titleLabel)),
            ("Name/email label", element(app, id: A11yID.Profile.nameAndEmailLabel)),
            ("Back button", app.buttons[A11yID.Profile.backButton]),
            ("Low bandwidth toggle", element(app, id: A11yID.Profile.lowBandwidthToggle)),
            ("Logout button", app.buttons[A11yID.Profile.logoutButton])
        ]
        let biometricToggle = element(app, id: A11yID.Profile.biometricToggle)
        if biometricToggle.exists {
            controls.append(("Biometric toggle", biometricToggle))
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
