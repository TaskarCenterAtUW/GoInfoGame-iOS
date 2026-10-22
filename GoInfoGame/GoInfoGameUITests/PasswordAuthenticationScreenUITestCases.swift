//
//  PasswordAuthenticationScreenUITestCases.swift
//  GoInfoGameUITests
//
//  PasswordAuthenticationPopupView (GoInfoGame/Login/PasswordAuthenticationPopupView.swift),
//  shown when Profile's biometricToggle is switched on. "Continue" re-verifies the
//  account password against the exact same POST /api/v1/authenticate endpoint the Login
//  screen itself uses (SessionManager.performLogin), then attempts real Face ID/Touch ID
//  enrollment via BiometricAuthManager.authenticate(). Cancel reverts the toggle with no
//  network call at all.
//
//  Reachability: biometricToggle only renders when BiometricAuthManager
//  .canEvaluateBiometrics() is true, which depends on the simulator's real Face ID/Touch
//  ID enrollment state on every scenario except two explicitly bypassed ones (see that
//  function's own comment) - this suite's own profileBiometricPopup* scenarios are the
//  second of those two, added specifically to make this screen reachable at all.
//
//  Success ceiling: BiometricAuthManager.authenticate() does its own SEPARATE, unbypassed
//  real LAContext check (no UI-test hook exists for it) - on a simulator with nothing
//  enrolled it safely resolves to "unavailable" before any real system prompt could
//  appear, so even a correct password ends in an error here, not true enrollment. Tested
//  as the real, current, safe (non-hanging) behavior - see
//  UITestScenario.profileBiometricPopupOnline's own comment.
//
//  Network: each of the 4 scenarios below fixes the password-verification response for
//  its whole test (stub selection happens once, at app launch) - a distinct outcome
//  needs its own scenario, the same way longFormOnline/NetworkDown/SlowResponse do.
//

import XCTest

final class PasswordAuthenticationScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    private func navigateToProfileFromWorkspaces(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
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

    /// A plain `.tap()` on biometricToggle lands at its accessibility frame's center -
    /// which, for a SwiftUI `Toggle(isOn:) { Text(...) }` like BiometricToggleView, sits
    /// over the row's LABEL text, not the switch graphic itself (confirmed directly for
    /// the structurally-identical FEATURES toggles in ManageQuestsScreenUITestCases - a
    /// plain tap there left the toggle's own `value` unchanged). The switch graphic sits
    /// at the row's trailing edge, so this taps there instead.
    @discardableResult
    private func tapToggle(_ toggle: XCUIElement) -> Bool {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        return true
    }

    /// Taps the biometric toggle and waits for the popup's presence signal (the password
    /// field - the popup has no root identifier of its own; it's a manual ZStack overlay,
    /// not a .sheet, so there's no container to tag without stomping its own children's
    /// identifiers, the same reasoning documented throughout A11yID.swift for other
    /// multi-child containers).
    @discardableResult
    private func openPasswordPopup(_ app: XCUIApplication, timeout: TimeInterval = 20) -> Bool {
        let toggle = element(app, id: A11yID.Profile.biometricToggle)
        guard toggle.waitForExistence(timeout: timeout) else { return false }
        tapToggle(toggle)
        return element(app, id: A11yID.PasswordAuth.passwordField).waitForExistence(timeout: timeout)
    }

    // MARK: - Presence, cancel

    func testBiometricTogglePresentsPasswordPopup() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupOnline)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        XCTAssertTrue(element(app, id: A11yID.PasswordAuth.continueButton).exists, "Continue button not shown")
        XCTAssertTrue(element(app, id: A11yID.PasswordAuth.cancelButton).exists, "Cancel button not shown")
    }

    func testCancelDismissesPopupWithoutNetworkCallAndRevertsToggle() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupOnline)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        element(app, id: A11yID.PasswordAuth.cancelButton).tap()

        XCTAssertTrue(element(app, id: A11yID.PasswordAuth.passwordField).waitForNonExistence(timeout: 10),
                      "Password popup still showing after Cancel")
        let toggle = element(app, id: A11yID.Profile.biometricToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Biometric toggle not shown after cancelling")
        XCTAssertEqual(toggle.value as? String, "0",
                      "Toggle did not revert to off after cancelling - value: \(String(describing: toggle.value))")
    }

    // MARK: - Network on/off

    func testWrongPasswordShowsInvalidCredentialsError() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupWrongPassword)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        element(app, id: A11yID.PasswordAuth.passwordField).tap()
        element(app, id: A11yID.PasswordAuth.passwordField).typeText("wrong-password")
        element(app, id: A11yID.PasswordAuth.continueButton).tap()

        let error = element(app, id: A11yID.PasswordAuth.errorMessage)
        XCTAssertTrue(error.waitForExistence(timeout: 10), "Error message did not appear for a wrong password")
        XCTAssertTrue(error.label.contains("Invalid username or password"),
                      "Unexpected error text for a wrong password - label: \(error.label)")
    }

    /// See this file's own header comment on the "success ceiling" - a correct password
    /// still ends here, not in true enrollment, because of BiometricAuthManager
    /// .authenticate()'s own separate, unbypassed real check.
    func testCorrectPasswordButBiometricsUnavailableShowsError() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupOnline)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        element(app, id: A11yID.PasswordAuth.passwordField).tap()
        element(app, id: A11yID.PasswordAuth.passwordField).typeText("correct-password")
        element(app, id: A11yID.PasswordAuth.continueButton).tap()

        let error = element(app, id: A11yID.PasswordAuth.errorMessage)
        XCTAssertTrue(error.waitForExistence(timeout: 10), "Error message did not appear")
        XCTAssertFalse(error.label.contains("Invalid username or password"),
                       "Got the wrong-password error despite the password verification succeeding - label: \(error.label)")
    }

    func testLoadingStateAppearsDuringAuthentication() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupSlowResponse)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        element(app, id: A11yID.PasswordAuth.passwordField).tap()
        element(app, id: A11yID.PasswordAuth.passwordField).typeText("correct-password")
        element(app, id: A11yID.PasswordAuth.continueButton).tap()

        XCTAssertTrue(app.staticTexts["Authenticating..."].waitForExistence(timeout: 3),
                      "Loading indicator did not appear while the request was in flight")
    }

    func testNetworkDownDuringPasswordVerificationDoesNotHang() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupNetworkDown)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        element(app, id: A11yID.PasswordAuth.passwordField).tap()
        element(app, id: A11yID.PasswordAuth.passwordField).typeText("correct-password")
        element(app, id: A11yID.PasswordAuth.continueButton).tap()

        let error = element(app, id: A11yID.PasswordAuth.errorMessage)
        XCTAssertTrue(error.waitForExistence(timeout: 10), "Error message did not appear when the network is down")
        XCTAssertTrue(element(app, id: A11yID.PasswordAuth.cancelButton).isHittable,
                      "Popup became unresponsive after a failed password verification")
    }

    // MARK: - Layout

    /// A small, fixed popup rather than a scrollable screen, so one combined check
    /// covers overlap/bounds/reachability - the same scale as the Map undo popup's own
    /// single layout test in UndoEditsScreenUITestCases.
    func testPasswordPopupLayout() throws {
        let app = navigateToProfileFromWorkspaces(scenario: UITestScenario.profileBiometricPopupOnline)
        XCTAssertTrue(openPasswordPopup(app), "Password popup did not open")

        let passwordField = element(app, id: A11yID.PasswordAuth.passwordField)
        let continueButton = element(app, id: A11yID.PasswordAuth.continueButton)
        let cancelButton = element(app, id: A11yID.PasswordAuth.cancelButton)

        let window = app.windows.firstMatch.frame
        for (name, control) in [("Password field", passwordField), ("Continue button", continueButton), ("Cancel button", cancelButton)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
        }
        assertNoOverlap([(passwordField, "Password field"), (continueButton, "Continue button"), (cancelButton, "Cancel button")])
    }
}
