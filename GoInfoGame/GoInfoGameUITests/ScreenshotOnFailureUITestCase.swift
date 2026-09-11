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
            let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
            attachment.name = "Failure screenshot - \(name)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
        super.tearDown()
    }
}
