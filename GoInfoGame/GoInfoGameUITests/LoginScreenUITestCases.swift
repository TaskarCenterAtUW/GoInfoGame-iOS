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
}
