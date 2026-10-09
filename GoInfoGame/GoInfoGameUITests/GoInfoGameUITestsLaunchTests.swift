//
//  GoInfoGameUITestsLaunchTests.swift
//  GoInfoGameUITests
//
//  Created by Achyut Kumar M on 09/11/23.
//

import XCTest

final class GoInfoGameUITestsLaunchTests: ScreenshotOnFailureUITestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    // No setUpWithError override here on purpose: the base class's registers the
    // system-alert interruption monitor, and a prior version of this override replaced it
    // without calling super, silently losing that monitor for this test class alone.

    func testLaunch() throws {
        // launchApp(...), not XCUIApplication().launch(): the raw call skips network
        // stubbing, state reset, and - critically for this screenshot - leaves
        // UITestRuntime.isActive false, so the real AppTransaction.shared call in
        // ForceUpdateManager fires and can show a SpringBoard "Sign in to Apple Account"
        // sandbox sheet over the freshly launched screen with nothing registered to
        // dismiss it, which is what an unscoped `app.screenshot()` right after launch
        // was capturing instead of the actual login screen.
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        // Give the real screen a moment to settle (and any system alert a moment to be
        // caught by the interruption monitor) before capturing what launch actually looks
        // like, rather than whatever transient state exists in the instant after launch().
        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].waitForExistence(timeout: 15),
                      "App did not reach the login screen before the launch screenshot")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
