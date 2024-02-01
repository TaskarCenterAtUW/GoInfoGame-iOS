//
//  HandRailTests.swift
//  GoInfoGameTests
//
//  Created by Achyut Kumar M on 01/02/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser

final class HandRailTests: XCTestCase {
    
    let handRail = HandRail()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /** Testing the query
     ways with highway = steps
     and (!indoor and indoor = no)
     and access !~ private|no
     and (!conveying or conveying = no)
     and (
         !handrail and !handrail:center and !handrail:left and !handrail:left
         or handrail = no and handrail older today -4 years
         or handrail older today -8 years
         or older today -8 years
     )
     
     */
    
    func testHandRailQuery() throws {
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["" : ""]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "residential"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "conveying": "yes"])) // conveying is not allowed
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "indoor": "yes"])) // indoor is not allowed
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "handrail": "no", "handrail:date": "2019-01-31"])) // handrail older than 8 years
//        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "handrail": "no", "handrail:date": "2013-01-31"])) // older than 8 years
    }

    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(handRail.isApplicable(element: element))
    }

    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(handRail.isApplicable(element: element))
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
