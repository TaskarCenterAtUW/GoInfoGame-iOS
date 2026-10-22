//
//  ForceUpdateScreenUITestCases.swift
//  GoInfoGameUITests
//
//  ForceUpdateViewModifier (GoInfoGame/ForceUpdateViewModifier.swift) - not a screen of
//  its own, a .alert() applied to the app's root view (Workspaces/InitialView when
//  logged in, PosmLoginView when logged out - identical modifier on both).
//  ForceUpdateManager.checkForceUpdate() (GoInfoGame/ForceUpdateManager.swift) fires on
//  every sceneDidBecomeActive, including a cold launch, so no extra foreground step is
//  needed - launchApp(scenario:) alone is enough to trigger it.
//
//  Native SwiftUI Alert, so - same documented exception this project already makes for
//  the iOS 26 toolbar overflow's "More" menu and other system/OS-owned UI - matched by
//  its fixed English title/button text (A11yID.swift's own header comment on why
//  identifiers are normally never label-derived), since a plain Alert carries no
//  accessibilityIdentifier hook at all.
//
//  Deliberately does NOT tap "Update" in any test: openAppStore() calls
//  UIApplication.shared.open(url), which would switch away from this app entirely
//  (Safari/TestFlight) - an external app switch with no clean way back for the next
//  test, and not something a UI test should trigger as a side effect of just confirming
//  a button exists.
//

import XCTest

final class ForceUpdateScreenUITestCases: ScreenshotOnFailureUITestCase {

    func testNoUpdateShowsNoAlert() throws {
        let app = launchApp(scenario: UITestScenario.forceUpdateNone)

        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 20),
                      "Did not land on the Workspaces screen")
        XCTAssertFalse(app.alerts["Update Required"].waitForExistence(timeout: 3), "Force-update alert shown despite no update being required")
        XCTAssertFalse(app.alerts["Update Available"].exists, "Soft-update alert shown despite no update being required")
    }

    func testSoftUpdateShowsDismissableAlert() throws {
        let app = launchApp(scenario: UITestScenario.forceUpdateSoft)

        let alert = app.alerts["Update Available"]
        XCTAssertTrue(alert.waitForExistence(timeout: 20), "Soft-update alert did not appear")
        XCTAssertTrue(alert.staticTexts["A new version of the app is available. Would you like to update now?"].exists,
                      "Soft-update alert message text not found")
        XCTAssertTrue(alert.buttons["Update"].exists, "Update button not shown")
        XCTAssertTrue(alert.buttons["Cancel"].exists, "Cancel button not shown - soft update should be dismissable")

        alert.buttons["Cancel"].tap()

        XCTAssertTrue(app.staticTexts[A11yID.Workspaces.title].waitForExistence(timeout: 10),
                      "Workspaces screen not usable after dismissing the soft-update alert")
        XCTAssertFalse(alert.exists, "Soft-update alert still showing after tapping Cancel")
    }

    /// Doesn't attempt to prove the app is fully "blocked" (there's no way to dismiss
    /// this alert without tapping Update, which this suite deliberately never taps -
    /// see this file's own header comment) - confirms the alert appears with the
    /// expected text and, crucially, has no Cancel/dismiss option at all, unlike the
    /// soft-update case.
    func testForceUpdateShowsBlockingAlertWithNoCancelOption() throws {
        let app = launchApp(scenario: UITestScenario.forceUpdateForce)

        let alert = app.alerts["Update Required"]
        XCTAssertTrue(alert.waitForExistence(timeout: 20), "Force-update alert did not appear")
        XCTAssertTrue(alert.staticTexts["A new version of the app is available. Please update to continue using the app."].exists,
                      "Force-update alert message text not found")
        XCTAssertTrue(alert.buttons["Update"].exists, "Update button not shown")
        XCTAssertFalse(alert.buttons["Cancel"].exists, "Cancel button present - force update should not be dismissable")
    }
}
