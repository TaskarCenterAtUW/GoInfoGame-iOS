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

        // SpringBoard's account sign-in nag ("Sign in with Apple ID" on older OS versions,
        // "Sign in to Apple Account" on newer ones - Apple has renamed it, so this does not
        // match on title) can appear on a fresh simulator independent of any app: on the
        // Home Screen before anything is launched, mid-test, or after backgrounding.
        // XCTest's own default handler has been observed spending 60+ seconds fighting a
        // respawning instance of it. This monitor dismisses it in one step instead; the
        // description string is only a debug label, not a match filter, so it fires for
        // whatever system alert is actually showing.
        addUIInterruptionMonitor(withDescription: "System account sign-in nag") { alert in
            let cancel = alert.buttons["Cancel"]
            guard cancel.exists else { return false }
            cancel.tap()
            return true
        }

        // A simulator that has never granted GoInfoGame location access before (a fresh
        // Erase All Content and Settings, or a CI machine's first run) shows the system
        // "Allow Location" alert the moment CLLocationManager's delegate is assigned
        // (LocationManagerDelegate.locationManagerDidChangeAuthorization fires with
        // .notDetermined on launch and immediately calls requestWhenInUseAuthorization()).
        // That's unconditional, unlike startUpdatingLocation's own UITestRuntime bypass
        // (LocationManagerDelegate.swift's own comment) - the bypass only skips the real
        // GPS fix, not this authorization prompt. Left unhandled, the alert sits in front
        // of the whole app and every test that needs the Map screen times out identically
        // ("Form did not open" etc.), independent of whatever that test is actually
        // checking. Tapping any allow option is fine either way: the app never uses the
        // real coordinate under UITestRuntime.isActive regardless of what's granted here.
        addUIInterruptionMonitor(withDescription: "Location permission request") { alert in
            for title in ["Allow While Using App", "Allow Once", "Allow"] {
                let button = alert.buttons[title]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
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
        // "Cancel" dismisses the sign-in nag; the location-permission alert (see the
        // "Location permission request" interruption monitor in setUpWithError, whose own
        // comment explains why it shows up and why any allow option is fine to tap) uses a
        // different button set entirely, so both are tried here.
        for title in ["Cancel", "Allow While Using App", "Allow Once", "Allow"] {
            let button = alert.buttons[title]
            if button.exists {
                button.tap()
                break
            }
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
            app.launchEnvironment[UITestScenario.environmentKey] = scenario
        }
        if resetState {
            // Defaults to on: a test that logs in successfully leaves `loggedIn = true`
            // in UserDefaults and tokens in the Keychain (which outlives even deleting the
            // app), so without this the next test would launch past the login screen.
            app.launchArguments.append(UITestScenario.resetStateArgument)
        }
        app.launch()
        // Deterministic, not just the passive interruption monitor above: that monitor is
        // only consulted when XCTest happens to synchronize on a query, and this comment's
        // sibling on the sign-in nag already found that unreliable enough to warrant an
        // explicit check. The location-permission alert (see setUpWithError) can appear
        // this early, before any test has made its own query yet.
        dismissSystemAlertsIfPresent(app)
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
        let viewport = XCUIApplication().windows.firstMatch.frame
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            // A row a List hasn't materialized yet (lazy virtualization - unlike every
            // ScrollView-based screen this helper was originally written against)
            // doesn't just sit off-screen, it plain doesn't exist, reporting a .zero
            // frame. Trusting frame.midY (reads as 0) for direction in that case
            // reads as "already above the viewport" and scrolls the wrong way for a
            // target that's actually further down and simply hasn't rendered yet -
            // confirmed directly: a question only a few rows into a real List failed
            // to ever become reachable under the old guard (`element.exists` returning
            // false immediately, before a single scroll was attempted) combined with
            // this misread direction once existence was allowed to retry instead.
            // Default to revealing more content below whenever the element isn't real
            // yet; only trust its actual frame for direction once it exists.
            if element.exists && element.frame.midY > viewport.midY {
                scrollView.swipeUp()
            } else {
                scrollView.swipeDown()
            }
            swipes += 1
        }
        return element.exists && element.isHittable
    }

    /// Asserts that no two of `elements` share any on-screen area.
    ///
    /// Only currently-existing elements are compared - a SwiftUI view hidden behind a
    /// conditional (e.g. one of several mutually-exclusive branches) still has a frame,
    /// usually .zero, and comparing it would either produce a false failure or a false
    /// pass depending on where .zero happens to land, neither of which says anything about
    /// a real layout bug. Callers pass only the elements meant to be visible together.
    ///
    /// Every pair is checked once (`i < j`), not `count^2` times, so a single genuine
    /// overlap between A and B is reported once, under whichever of the two names sorts
    /// first in the input, rather than twice.
    func assertNoOverlap(_ elements: [(element: XCUIElement, name: String)],
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let visible = elements.filter { $0.element.exists }
        guard visible.count > 1 else { return }
        for i in 0..<(visible.count - 1) {
            for j in (i + 1)..<visible.count {
                let (elementA, nameA) = visible[i]
                let (elementB, nameB) = visible[j]
                XCTAssertFalse(elementA.frame.intersects(elementB.frame),
                               "\(nameA) overlaps \(nameB) (\(elementA.frame) vs \(elementB.frame))",
                               file: file, line: line)
            }
        }
    }

    override func tearDown() {
        if let run = testRun, run.failureCount > 0 {
            // XCUIScreen.main rather than XCUIApplication().screenshot(): the latter
            // screenshots a fresh app handle, so when a test fails because the app
            // crashed or was never launched it captures a blank frame or SpringBoard.
            // The screen always shows whatever was actually in front at the moment of
            // failure, which is the thing worth looking at.
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            // `name` (XCTestCase) prints as the Objective-C style "-[Class testMethod]".
            // Keep the class and method in the attachment name - the CI report generator
            // uses them to match this image to its failing test - but strip the "-[ ]"
            // so the resulting filename stays free of brackets, which have broken
            // downstream Markdown/HTML parsing before. Result: "Failure screenshot -
            // Class testMethod".
            let testName = name.trimmingCharacters(in: CharacterSet(charactersIn: "-[] "))
            attachment.name = "Failure screenshot - \(testName)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
        super.tearDown()
    }
}
