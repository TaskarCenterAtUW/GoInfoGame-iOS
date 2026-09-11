//
//  ScreenshotOnFailureUITestCase.swift
//  GoInfoGameUITests
//
//  Base class for UI test cases: automatically attaches a screenshot to any test
//  that fails, with no per-test or per-assert code needed. Subclass this instead
//  of XCTestCase and every test method gets it for free, since tearDown() runs
//  once after each test method regardless of how many assertions it made.
//

import XCTest

class ScreenshotOnFailureUITestCase: XCTestCase {
    override func tearDown() {
        if let run = testRun, run.failureCount > 0 {
            // Plain name on purpose: `name` (XCTestCase) prints as the Objective-C
            // style "-[Class testMethod]", and those brackets have broken downstream
            // Markdown/HTML parsing of the resulting filename before. The test/suite
            // is already shown in the report's failure heading, so no need to repeat
            // it here - xcparse still files this under that test's own folder.
            let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
            attachment.name = "Failure screenshot"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
        super.tearDown()
    }
}
