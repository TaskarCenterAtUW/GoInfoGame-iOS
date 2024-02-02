//
//  StepsRampTests.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/01/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser

final class StepsRampTests: XCTestCase {
    
    let dbInstance = DatabaseConnector.shared
    var nodes: [Node] = []
    var ways: [Way] = []
    let stepsRamp = StepsRamp()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /** Testing the query
     ways with highway = steps
              and (!indoor or indoor = no)
              and access !~ private|no
              and (!conveying or conveying = no)
              and ramp != separate
              and (
                !ramp
                or (ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair)
                or ramp = no and ramp older today -4 years
                or ramp older today -8 years
              )
     
     */
    
    func testStepsRampQuery() throws {
        let fourYearsAgo = TestQuestUtils.olderThan(years: -4)
        let eightYearsAgo = TestQuestUtils.olderThan(years: -8)

        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["" : ""]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "access": "private"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "conveying": "no"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "ramp": "seperate"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "ramp": "yes", "ramp:stroller": "yes", "ramp:bicycle": "yes", "ramp:wheelchair": "yes"])) // all ramp types are not allowed
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "steps", "conveying": "yes"])) // conveying is not allowed
        
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "indoor": "no", "access": "yes", "conveying": "no"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "indoor": "no", "access": "yes", "conveying": "no", "ramp": "yes"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "indoor": "no", "access": "yes", "conveying": "no", "ramp": "no"], timestamp: fourYearsAgo))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "indoor": "no", "access": "yes", "conveying": "no"], timestamp: eightYearsAgo))

    }
    
   
    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(stepsRamp.isApplicable(element: element))
    }
    
    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(stepsRamp.isApplicable(element: element))
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
