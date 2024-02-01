//
//  StepsInclineTests.swift
//  GoInfoGameTests
//
//  Created by Achyut Kumar M on 31/01/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser

final class StepsInclineTests: XCTestCase {
    
    let stepsIncline = StepsIncline()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /** Testing the query
     ways with highway = steps
      and (!indoor or indoor = no)
      and area != yes
      and access !~ private|no
      and !incline
     
     */
    
    func testStepsInclineQuery() {
        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["" : ""]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "residential"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["access" : "private"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["incline": "false"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "indoor": "yes"])) // indoor is not allowed
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "area": "yes"])) // area is not allowed
    }
    
    
    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(stepsIncline.isApplicable(element: element))
    }
    
    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(stepsIncline.isApplicable(element: element))
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
