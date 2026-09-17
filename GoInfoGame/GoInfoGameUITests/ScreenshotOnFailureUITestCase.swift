//
//  ScreenshotOnFailureUITestCase.swift
//  GoInfoGameUITests
//
//  Base class for UI test cases: automatically attaches a screenshot to any test
//  that fails, with no per-test or per-assert code needed. Subclass this instead
//  of XCTestCase and every test method gets it for free, since tearDown() runs
//  once after each test method regardless of how many assertions it made.
//
//  It also owns app launch, so every test starts the app the same way and picks its
//  network scenario declaratively.
//

import XCTest

class ScreenshotOnFailureUITestCase: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // The simulator's iCloud Keychain can offer "Sign in with Apple ID" as an
        // AutoFill suggestion over any screen with an adjacent username/password field,
        // whenever the Mac/simulator has an Apple ID signed in. `.textContentType` on the
        // fields (see FloatingLabelTextField/SecureInputView) makes this rare, but it is a
        // simulator-account-state condition, not something the app can guarantee against -
        // XCTest's own default handler has been observed spending 60+ seconds fighting it
        // when it does appear. This monitor dismisses it in one step instead.
        addUIInterruptionMonitor(withDescription: "Sign in with Apple ID") { alert in
            let cancel = alert.buttons["Cancel"]
            guard cancel.exists else { return false }
            cancel.tap()
            return true
        }
    }

    /// Dismisses the "Sign in with Apple ID" AutoFill sheet if it is currently showing.
    ///
    /// That sheet is owned by SpringBoard, not by GoInfoGame (confirmed in a hung run's
    /// log: "Invoking UI interruption monitors ... Application 'com.apple.springboard'"),
    /// so it is invisible to `app.alerts` - that query is scoped to the GoInfoGame process.
    /// It has to be looked up through a separate XCUIApplication handle for SpringBoard.
    ///
    /// A blind "poke" tap on the app (e.g. `app.tap()`) is not a substitute: the sheet is
    /// roughly centered on screen, so a poke aimed at the app's center can land on the
    /// sheet's own text field instead of dismissing it, leaving it in front and the
    /// underlying field still unfocused. Querying and tapping Cancel directly is
    /// deterministic regardless of exactly when XCTest would have run its own interruption
    /// handling.
    ///
    /// Call this after any tap that could focus a credential-looking field (username,
    /// password) - that is what raises the sheet - before assuming the tap landed where
    /// intended.
    @discardableResult
    func dismissSystemAlertsIfPresent(_ app: XCUIApplication) -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 1) else { return false }
        if alert.buttons["Cancel"].exists {
            alert.buttons["Cancel"].tap()
        }
        _ = alert.waitForNonExistence(timeout: 3)
        return true
    }

    /// Launches the app for a test, optionally under a stubbed network scenario.
    ///
    /// Use this rather than `XCUIApplication().launch()` directly - and never
    /// `activate()`, which reuses a running instance and silently drops
    /// launchEnvironment, so the scenario would never reach the app.
    ///
    /// `scenario` must be one of `UITestScenario`; the app reads
    /// it from its own ProcessInfo at launch and registers the matching stubs there.
    /// Stubs cannot be registered from this process - see UITestStubs.swift for why.
    @discardableResult
    func launchApp(scenario: String? = nil, resetState: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        if let scenario {
            app.launchEnvironment["UITEST_SCENARIO"] = scenario
        }
        if resetState {
            // Defaults to on: a test that logs in successfully leaves `loggedIn = true`
            // in UserDefaults and tokens in the Keychain (which outlives even deleting the
            // app), so without this the next test would launch past the login screen.
            app.launchArguments.append(UITestScenario.resetStateArgument)
        }
        app.launch()
        return app
    }

    /// Minimum tap target Apple's accessibility guidance asks for, in points.
    static let minimumTapTarget: CGFloat = 44

    /// Looks an element up by identifier without committing to an element type.
    ///
    /// Useful when SwiftUI's choice of type is not obvious or can change - a combined
    /// container may surface as `other` or `staticText` depending on its contents, and a
    /// wrong guess reads as "element missing" rather than as the type mismatch it is.
    func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Scrolls `element` into view, then reports whether it ended up actually reachable.
    ///
    /// On a short screen a login field can sit below the fold - that is not a defect,
    /// because the form is inside a ScrollView and the user scrolls to it. So a test
    /// asserting an element is usable has to do what the user would do first, and only
    /// then check `isHittable`. Asserting `isHittable` cold would fail on small devices
    /// for elements that are perfectly reachable.
    ///
    /// Scroll direction is derived from the element's own frame, which XCUITest reports
    /// in screen coordinates even while the element is scrolled out of view.
    @discardableResult
    func scrollToElement(_ element: XCUIElement,
                         in scrollView: XCUIElement,
                         maxSwipes: Int = 8) -> Bool {
        guard element.exists else { return false }
        let viewport = XCUIApplication().windows.firstMatch.frame
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            if element.frame.midY > viewport.midY {
                scrollView.swipeUp()
            } else {
                scrollView.swipeDown()
            }
            swipes += 1
        }
        return element.isHittable
    }

    override func tearDown() {
        if let run = testRun, run.failureCount > 0 {
            // XCUIScreen.main rather than XCUIApplication().screenshot(): the latter
            // screenshots a fresh app handle, so when a test fails because the app
            // crashed or was never launched it captures a blank frame or SpringBoard.
            // The screen always shows whatever was actually in front at the moment of
            // failure, which is the thing worth looking at.
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            // Plain name on purpose: `name` (XCTestCase) prints as the Objective-C
            // style "-[Class testMethod]", and those brackets have broken downstream
            // Markdown/HTML parsing of the resulting filename before. The test/suite
            // is already shown in the report's failure heading, so no need to repeat
            // it here - xcparse still files this under that test's own folder.
            attachment.name = "Failure screenshot"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
        super.tearDown()
    }
}
