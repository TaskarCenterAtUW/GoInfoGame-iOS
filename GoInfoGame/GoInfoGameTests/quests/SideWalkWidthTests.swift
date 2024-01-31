//
//  SideWalkWidthTests.swift
//  GoInfoGameTests
//
//  Created by Achyut Kumar M on 01/02/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser

final class SideWalkWidthTests: XCTestCase {
    
    let sideWalkWidth = SideWalkWidth()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /** Testing the query
         ways with
         ( highway = footway
         or foot = yes)
         and !width
     */
    
    func testFootwayQuery() throws {
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["" : ""]))
        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["highway": "residential"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway": "footway"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["foot": "yes"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway": "footway", "foot": "no"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway": "footway", "width": "no"]))
    }

    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(sideWalkWidth.isApplicable(element: element))
    }

    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(sideWalkWidth.isApplicable(element: element))
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
