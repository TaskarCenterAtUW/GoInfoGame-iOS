//
//  GoInfoGameUITests.swift
//  GoInfoGameUITests
//
//  Created by Achyut Kumar M on 09/11/23.
//
//  App-level UI tests that are not tied to one screen. Per-screen coverage lives in its
//  own file (e.g. LoginScreenUITestCases).
//

import XCTest

final class GoInfoGameUITests: ScreenshotOnFailureUITestCase {

    /// The app gets to its first interactive screen without crashing, with the network
    /// stubbed so this says something about the app rather than about connectivity.
    func testAppLaunchesToLoginScreen() throws {
        let app = launchApp(scenario: UITestScenario.loginInvalidCredentials)

        XCTAssertTrue(app.buttons[A11yID.Login.loginButton].waitForExistence(timeout: 15),
                      "App did not reach the login screen after launch")
    }
}
