//
//  GoInfoGameUITests.swift
//  GoInfoGameUITests
//
//  Created by Achyut Kumar M on 09/11/23.
//

import XCTest

final class GoInfoGameUITests: ScreenshotOnFailureUITestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testFaildLogin() throws {
        let app = XCUIApplication()
        app.launch()
        app/*@START_MENU_TOKEN@*/.textFields["Username"]/*[[".otherElements.textFields[\"Username\"]",".textFields",".textFields[\"Username\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        let element = app/*@START_MENU_TOKEN@*/.secureTextFields["Password"]/*[[".otherElements.secureTextFields[\"Password\"]",".secureTextFields",".secureTextFields[\"Password\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        element.tap()
        element.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Login"]/*[[".otherElements.buttons[\"Login\"]",".buttons[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Forgot password?"]/*[[".otherElements.buttons[\"Forgot password?\"]",".buttons[\"Forgot password?\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.swipeUp()
        XCTAssert(false, "Testing failed case with screenshot.")
        
    }
}
