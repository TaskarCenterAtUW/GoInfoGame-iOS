//
//  LoginScreenUITestCases.swift
//  GoInfoGameUITests
//
//  Created by Prashamsa on 16/09/26.
//
//  Every test launches with the network stubbed inside the app process and with persisted
//  state (UserDefaults + Keychain) cleared, so each one starts from the same login screen
//  regardless of what ran before it.
//

import XCTest

final class LoginScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    /// The login form is inside a ScrollView, so anything can legitimately start below the
    /// fold on a short screen. Every interaction goes through here.
    private func scroll(in app: XCUIApplication) -> XCUIElement {
        app.scrollViews[A11yID.Login.scrollView]
    }

    private func enterCredentials(_ app: XCUIApplication,
                                  username: String?,
                                  password: String?,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        let scrollView = scroll(in: app)

        if let username {
            let field = app.textFields[A11yID.Login.usernameField]
            XCTAssertTrue(field.waitForExistence(timeout: 15), "Username field not found", file: file, line: line)
            XCTAssertTrue(scrollToElement(field, in: scrollView), "Username field unreachable", file: file, line: line)
            field.tap()
            // A tap on the username field is exactly what can raise the system's
            // "Sign in with Apple ID" AutoFill sheet - check for it before typing, since
            // typing into a field that lost focus to that sheet fails with a keyboard-focus
            // error rather than a useful assertion failure.
            dismissSystemAlertsIfPresent(app)
            field.tap()
            field.typeText(username)
        }

        if let password {
            let field = app.secureTextFields[A11yID.Login.passwordField]
            XCTAssertTrue(field.waitForExistence(timeout: 5), "Password field not found", file: file, line: line)
            XCTAssertTrue(scrollToElement(field, in: scrollView), "Password field unreachable", file: file, line: line)
            field.tap()
            dismissSystemAlertsIfPresent(app)
            field.tap()
            field.typeText(password)
        }
    }

    private func tapLogin(_ app: XCUIApplication,
                          file: StaticString = #filePath,
                          line: UInt = #line) {
        let button = app.buttons[A11yID.Login.loginButton]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Login button not found", file: file, line: line)
        XCTAssertTrue(scrollToElement(button, in: scroll(in: app)), "Login button unreachable", file: file, line: line)
        button.tap()
    }

    private func assertLoginErrorShown(_ app: XCUIApplication,
                                       file: StaticString = #filePath,
                                       line: UInt = #line) {
        let error = app.staticTexts[A11yID.Login.errorMessage]
        XCTAssertTrue(error.waitForExistence(timeout: 15), "Error message did not appear", file: file, line: line)
        XCTAssertTrue(scrollToElement(error, in: scroll(in: app)),
                      "Error message could not be scrolled into view", file: file, line: line)
    }

    // MARK: - Negative login paths

    func testLoginWithWrongCredentials() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        enterCredentials(app, username: "test@email.com", password: "wrong-password\n")
        tapLogin(app)
        assertLoginErrorShown(app)

        // Identifier locates the element, label asserts the content, so a reworded message
        // reports as wrong text rather than as a missing element.
        XCTAssertEqual(app.staticTexts[A11yID.Login.errorMessage].label,
                       "Invalid Credentials", "Unexpected error message text")

        // A failed login must not navigate anywhere.
        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].exists,
                      "Login screen was dismissed despite the login failing")
        XCTAssertFalse(app.staticTexts[A11yID.Workspaces.title].exists,
                       "Navigated to the workspaces screen after a failed login")
    }

    func testLoginWhenServerReturnsError() throws {
        let app = launchApp(scenario: UITestScenario.loginServerError)

        enterCredentials(app, username: "test@email.com", password: "any-password\n")
        tapLogin(app)

        // A 500 is not a credentials problem, but the app must still surface something and
        // must not strand the user on a spinner.
        assertLoginErrorShown(app)
        XCTAssertFalse(element(app, id: A11yID.Login.loadingIndicator).exists,
                       "Loading indicator still visible after the server returned an error")
    }

    func testLoginWhenNetworkIsUnavailable() throws {
        let app = launchApp(scenario: UITestScenario.loginNetworkDown)

        enterCredentials(app, username: "test@email.com", password: "any-password\n")
        tapLogin(app)

        assertLoginErrorShown(app)
        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].exists,
                      "Login screen was dismissed after a network failure")
    }

    // MARK: - Successful login

    func testLoginWithValidCredentialsNavigatesToWorkspaces() throws {
        let app = launchApp(scenario: UITestScenario.loginSuccess)

        enterCredentials(app, username: "test@email.com", password: "correct-password\n")
        tapLogin(app)

        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 20),
                      "Did not navigate to the workspaces screen after a successful login")
        XCTAssertFalse(app.staticTexts[A11yID.Login.errorMessage].exists,
                       "Error message shown despite the login succeeding")
    }

    // MARK: - Client-side validation

    func testLoginWithEmptyUsernameShowsValidationAlert() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        enterCredentials(app, username: nil, password: "some-password\n")
        tapLogin(app)

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No validation alert for a missing username")
        XCTAssertTrue(alert.staticTexts["Username is required."].exists,
                      "Validation alert did not name the missing username field")
        alert.buttons["OK"].tap()
    }

    func testLoginWithEmptyPasswordShowsValidationAlert() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        enterCredentials(app, username: "test@email.com\n", password: nil)
        tapLogin(app)

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No validation alert for a missing password")
        XCTAssertTrue(alert.staticTexts["Password is required."].exists,
                      "Validation alert did not name the missing password field")
        alert.buttons["OK"].tap()
    }

    func testLoginWithBothFieldsEmptyShowsValidationAlert() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        tapLogin(app)

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No validation alert for an empty form")
        XCTAssertTrue(alert.staticTexts["Enter username and password"].exists,
                      "Validation alert did not prompt for both fields")
        alert.buttons["OK"].tap()

        // Dismissing the alert must leave the user on the login screen, not mid-request.
        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].exists, "Login screen gone after dismissing the alert")
    }

    // MARK: - Loading state

    func testLoadingIndicatorAppearsWhileLoginIsInFlight() throws {
        // This scenario delays the stubbed response; against an instant stub the spinner
        // would come and go faster than XCUITest could ever observe it.
        let app = launchApp(scenario: UITestScenario.loginSlowResponse)

        enterCredentials(app, username: "test@email.com\n", password: "wrong-password\n")
        tapLogin(app)

        let spinner = element(app, id: A11yID.Login.loadingIndicator)
        XCTAssertTrue(spinner.waitForExistence(timeout: 3), "Loading indicator did not appear while logging in")

        assertLoginErrorShown(app)
        XCTAssertFalse(spinner.exists, "Loading indicator did not disappear after the response arrived")
    }

    // MARK: - Password visibility

    func testPasswordVisibilityToggleRevealsAndHidesPassword() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        enterCredentials(app, username: nil, password: "visible-secret")

        let toggle = app.buttons[A11yID.Login.passwordVisibilityToggle]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Password visibility toggle not found")
        XCTAssertTrue(scrollToElement(toggle, in: scroll(in: app)), "Password visibility toggle unreachable")

        // While masked the field is a secureTextField; revealing it swaps in a plain
        // TextField carrying the same identifier, which is what makes this observable.
        XCTAssertTrue(app.secureTextFields[A11yID.Login.passwordField].exists,
                      "Password field is not masked by default")

        toggle.tap()
        let revealed = app.textFields[A11yID.Login.passwordField]
        XCTAssertTrue(revealed.waitForExistence(timeout: 5), "Password did not become visible after tapping the toggle")
        XCTAssertEqual(revealed.value as? String, "visible-secret", "Revealed password does not match what was typed")

        toggle.tap()
        XCTAssertTrue(app.secureTextFields[A11yID.Login.passwordField].waitForExistence(timeout: 5),
                      "Password was not re-masked after tapping the toggle again")
    }

    // MARK: - Secondary actions

    /// These four all leave the app (Safari / Mail), so tapping them would strand the test
    /// outside the app under test. What is worth asserting is that a user can actually get
    /// to them: present, reachable by scrolling, and big enough to hit.
    func testSecondaryActionsAreReachableAndMeetTapTargetSize() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        let scrollView = scroll(in: app)

        let actions: [(String, String)] = [
            (A11yID.Login.forgotPasswordButton, "Forgot password?"),
            (A11yID.Login.newUserButton, "I'm a new user"),
            (A11yID.Login.contactUsButton, "Questions? Contact Us"),
            (A11yID.Login.accessMapButton, "Looking for AccessMap Route?")
        ]

        for (identifier, description) in actions {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.waitForExistence(timeout: 10), "\(description) not found on the login screen")
            XCTAssertTrue(scrollToElement(button, in: scrollView), "\(description) could not be scrolled into view")
            XCTAssertGreaterThanOrEqual(button.frame.height, Self.minimumTapTarget,
                                        "\(description) is shorter than the 44pt minimum tap target")
        }
    }

    // MARK: - Layout

    /// The form must stay usable on the narrowest supported screen: everything reachable,
    /// and nothing spilling outside the window horizontally.
    func testAllLoginControlsFitWithinTheScreenWidth() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        let window = app.windows.firstMatch
        let scrollView = scroll(in: app)

        let controls: [(String, XCUIElement)] = [
            ("Username field", app.textFields[A11yID.Login.usernameField]),
            ("Password field", app.secureTextFields[A11yID.Login.passwordField]),
            ("Login button", app.buttons[A11yID.Login.loginButton])
        ]

        for (description, control) in controls {
            XCTAssertTrue(control.waitForExistence(timeout: 10), "\(description) not found")
            XCTAssertTrue(scrollToElement(control, in: scrollView), "\(description) could not be scrolled into view")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX,
                                        "\(description) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX,
                                     "\(description) extends past the right edge of the screen")
        }
    }

    // MARK: - Debug mode
    //
    // The real trigger is 7 taps on the version label (PosmLogin.swift), but XCUITest
    // cannot reliably drive that native multi-tap gesture: its synthesized taps don't feed
    // UIKit's multi-tap recognizer the way a real finger does, no matter how they're paced
    // or padded from the test side (verified directly - identical taps worked instantly by
    // hand, never once under automation). Rather than change that gesture to accommodate
    // testing, PosmLogin.swift exposes one additional element - present only when
    // UITestRuntime.isActive, absent in Release and in ordinary manual DEBUG-build use -
    // that reaches the exact same `showEnableDebugModeAlert = true` state via a single
    // ordinary tap. Every test below uses that entry point, then exercises entirely real
    // app UI and logic (the alert, the environment picker, the disable flow) from there.
    //
    // What this means for coverage: fully automated below is everything the debug-mode
    // feature DOES once triggered. NOT automated, and needing a manual check instead, is
    // whether exactly 7 real taps (and not some other count) is what triggers it in
    // production - that specific detail is outside what XCUITest can verify here.

    @discardableResult
    private func unlockDebugModeAlert(_ app: XCUIApplication,
                                      file: StaticString = #filePath,
                                      line: UInt = #line) -> XCUIElement {
        let unlock = element(app, id: A11yID.Login.debugModeUITestUnlock)
        XCTAssertTrue(unlock.waitForExistence(timeout: 15), "Debug mode test-unlock element not found", file: file, line: line)
        XCTAssertTrue(scrollToElement(unlock, in: scroll(in: app)), "Debug mode test-unlock element unreachable", file: file, line: line)
        unlock.tap()
        return unlock
    }

    func testDebugModeAndErrorMessageAreHiddenOnLaunch() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].waitForExistence(timeout: 15),
                      "App did not reach the login screen")
        XCTAssertFalse(app.staticTexts[A11yID.Login.errorMessage].exists,
                       "Error message shown on a fresh launch, before any login attempt")
        XCTAssertFalse(element(app, id: A11yID.Login.environmentPicker).exists,
                       "Environment picker visible on a fresh launch - debug mode should start disabled")
        XCTAssertFalse(element(app, id: A11yID.Login.exitDebugModeButton).exists,
                       "Exit debug mode button visible on a fresh launch - debug mode should start disabled")
    }

    func testDebugModeAlertOffersEnableAndNotNow() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        unlockDebugModeAlert(app)

        let alert = app.alerts["Debug mode"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No alert after the debug-mode trigger")
        XCTAssertTrue(alert.staticTexts["Do you want to enable debug mode?"].exists,
                      "Alert message did not ask to enable debug mode")
        XCTAssertTrue(alert.buttons["Enable"].exists, "Alert missing an Enable button")
        XCTAssertTrue(alert.buttons["Not Now"].exists, "Alert missing a Not Now button")
    }

    func testDecliningEnableDebugModeAlertLeavesDebugModeOff() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        unlockDebugModeAlert(app)

        let alert = app.alerts["Debug mode"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No alert after the debug-mode trigger")
        alert.buttons["Not Now"].tap()

        XCTAssertFalse(element(app, id: A11yID.Login.environmentPicker).exists,
                       "Environment picker appeared despite declining the debug mode alert")
        XCTAssertFalse(element(app, id: A11yID.Login.exitDebugModeButton).exists,
                       "Exit debug mode button appeared despite declining the debug mode alert")
    }

    func testEnablingDebugModeShowsEnvironmentPickerWithAllThreeEnvironments() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        unlockDebugModeAlert(app)

        let alert = app.alerts["Debug mode"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No alert after the debug-mode trigger")
        alert.buttons["Enable"].tap()

        // The alert itself only offers Enable/Not Now - the three environments live in a
        // separate Menu that appears once debug mode is on, not inside the alert.
        let picker = element(app, id: A11yID.Login.environmentPicker)
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Environment picker did not appear after enabling debug mode")
        XCTAssertTrue(scrollToElement(picker, in: scroll(in: app)), "Environment picker unreachable")
        XCTAssertTrue(picker.label.contains("Production"), "Environment picker did not default to Production")

        picker.tap()

        // Menu items surface as top-level buttons (via UIMenu), not nested under the
        // picker's own element, so these are queried at the app level. The three names
        // (from APIEnvironment.displayString()) are not localized, so matching by label
        // text is safe and stable here.
        for name in ["Development", "Staging", "Production"] {
            XCTAssertTrue(app.buttons[name].waitForExistence(timeout: 3),
                          "\(name) missing from the environment menu")
        }

        app.buttons["Staging"].tap()
        XCTAssertTrue(picker.label.contains("Staging"), "Environment picker did not update after selecting Staging")
    }

    func testExitDebugModeDisablesDebugModeAndResetsEnvironment() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        unlockDebugModeAlert(app)
        app.alerts["Debug mode"].buttons["Enable"].tap()

        let picker = element(app, id: A11yID.Login.environmentPicker)
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Environment picker did not appear after enabling debug mode")
        XCTAssertTrue(scrollToElement(picker, in: scroll(in: app)), "Environment picker unreachable")
        picker.tap()
        XCTAssertTrue(app.buttons["Staging"].waitForExistence(timeout: 3), "Staging option not found")
        app.buttons["Staging"].tap()
        XCTAssertTrue(picker.label.contains("Staging"), "Environment did not switch to Staging")

        let exitButton = element(app, id: A11yID.Login.exitDebugModeButton)
        XCTAssertTrue(exitButton.waitForExistence(timeout: 5), "Exit debug mode button not found")
        XCTAssertTrue(scrollToElement(exitButton, in: scroll(in: app)), "Exit debug mode button unreachable")
        exitButton.tap()

        let disableAlert = app.alerts["Debug mode"]
        XCTAssertTrue(disableAlert.waitForExistence(timeout: 5), "No alert after tapping Exit debug mode")
        XCTAssertTrue(disableAlert.staticTexts["Do you want to disable debug mode?"].exists,
                      "Alert message did not ask to disable debug mode")
        disableAlert.buttons["Disable"].tap()

        XCTAssertFalse(element(app, id: A11yID.Login.environmentPicker).exists,
                       "Environment picker still visible after disabling debug mode")
        XCTAssertFalse(element(app, id: A11yID.Login.exitDebugModeButton).exists,
                       "Exit debug mode button still visible after disabling debug mode")

        // Confirm the reset actually took effect, not just that the picker is hidden: enable
        // debug mode again and check it comes back showing Production rather than the
        // Staging it was left on.
        unlockDebugModeAlert(app)
        app.alerts["Debug mode"].buttons["Enable"].tap()
        let pickerAgain = element(app, id: A11yID.Login.environmentPicker)
        XCTAssertTrue(pickerAgain.waitForExistence(timeout: 5), "Environment picker did not reappear")
        XCTAssertTrue(pickerAgain.label.contains("Production"),
                      "Environment was not reset to Production when debug mode was disabled")
    }

    // MARK: - Debug mode / biometric reachability

    func testDebugModeActionButtonsAreReachableAndTappable() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)
        unlockDebugModeAlert(app)
        app.alerts["Debug mode"].buttons["Enable"].tap()

        let scrollView = scroll(in: app)
        let buttons: [(XCUIElement, String)] = [
            (element(app, id: A11yID.Login.environmentPicker), "Environment picker"),
            (element(app, id: A11yID.Login.exitDebugModeButton), "Exit debug mode button")
        ]

        for (button, description) in buttons {
            XCTAssertTrue(button.waitForExistence(timeout: 10), "\(description) not found")
            XCTAssertTrue(scrollToElement(button, in: scrollView), "\(description) could not be scrolled into view")
            XCTAssertGreaterThanOrEqual(button.frame.height, Self.minimumTapTarget,
                                        "\(description) is shorter than the 44pt minimum tap target")
        }
    }

    func testBiometricLoginButtonIsReachableAndTappableWhenAvailable() throws {
        // Only this scenario seeds Keychain + the biometric-enabled flag; every other
        // scenario runs through resetStateIfNeeded()'s usual force-declined state, so this
        // button is otherwise unreachable by any other test in this suite.
        let app = launchApp(scenario: UITestScenario.loginBiometricAvailable)

        let button = element(app, id: A11yID.Login.biometricButton)
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Biometric login button not found")
        XCTAssertTrue(scrollToElement(button, in: scroll(in: app)), "Biometric login button unreachable")
        XCTAssertGreaterThanOrEqual(button.frame.height, Self.minimumTapTarget,
                                    "Biometric login button is shorter than the 44pt minimum tap target")

        // Deliberately not tapped: doing so invokes LocalAuthentication and shows a real
        // system Face ID/Touch ID prompt with no deterministic outcome to assert on.
        // Presence, reachability and tap-target size are what "visible ... and tappable"
        // calls for here; actually completing biometric auth is out of scope for XCUITest.
    }
}
