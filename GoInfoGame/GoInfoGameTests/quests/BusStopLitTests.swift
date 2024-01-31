//
//  BusStopLitTests.swift
//  GoInfoGameTests
//
//  Created by Achyut Kumar M on 31/01/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser


final class BusStopLitTests: XCTestCase {
    
    let busStopLit = BusStopLit()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /** Testing the query
     nodes, ways, relations with
             (
               public_transport = platform
               or (highway = bus_stop and public_transport != stop_position)
             )
             and physically_present != no and naptan:BusStopType != HAR
             and location !~ underground|indoor
             and indoor != yes
             and (!level or level >= 0)
             and (
               !lit
               or lit = no and lit older today -8 years
               or lit older today -16 years
             )
     
     */
    
    func testBusStopLitQuery() throws {
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["" : ""]))
        assertIsNotApplicable(element: TestQuestUtils.rel(tags: ["public_transport" :"platform", "indoor" : "no" ]))
        assertIsApplicable(element: TestQuestUtils.node(tags: ["public_transport": "platform"]))
        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["highway": "bus_stop", "public_transport": "stop_position", "physically_present": "yes", "naptan:BusStopType": "HAR", "location": "underground", "indoor": "no", "level": "1", "lit": "no"]))
        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["public_transport": "platform", "physically_present": "no"])) // physically_present is not allowed to be 'no'
        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["public_transport": "platform", "lit": "yes", "lit:date": "2015-01-31"])) // lit older than 8 years
        assertIsApplicable(element: TestQuestUtils.node(tags: ["public_transport": "platform", "level": "0"]))
    }
    
    
    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(busStopLit.isApplicable(element: element))
    }
    
    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(busStopLit.isApplicable(element: element))
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
