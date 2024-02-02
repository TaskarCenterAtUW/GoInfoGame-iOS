//
//  TactilePavingStepsTests.swift
//  GoInfoGameTests
//
//  Created by Rajesh Kantipudi on 23/01/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser

final class TactilePavingStepsTests: XCTestCase {
    
    let dbInstance = DatabaseConnector.shared
    var nodes: [Node] = []
    var ways: [Way] = []
    let tactilePavingSteps = TactilePavingSteps()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFilterString() throws {
        let tactilePavingQuest = TactilePavingSteps()
        print(tactilePavingQuest.filter)
    }
    
    /** Testing the query
     ways with highway = steps
              and surface ~ \(PavedTypes.anythingPaved.joined(separator: "|"))
              and (!conveying or conveying = no)
              and access !~ private|no
             and (
               !tactile_paving
               or tactile_paving = unknown
               or tactile_paving ~ no|partial|incorrect and tactile_paving older today -4 years
               or tactile_paving = yes and tactile_paving older today -8 years
             )
     */
    

    
    func testtactilePavingStepsQuery() throws {
        
        let fourYearsAgo = TestQuestUtils.addTime(years: -4)
        let eightYearsAgo = TestQuestUtils.addTime(years: -8)
        let twoTwoYearsAgo = TestQuestUtils.addTime(years: -2)
        

        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["" : ""]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "access": "no"]))
        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["highway": "residential"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "surface": "paved"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "surface": "paved", "tactile_paving": "unknown"]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "surface": "paved", "tactile_paving": "incorrect"], timestamp: fourYearsAgo))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "surface": "paved", "tactile_paving": "yes"], timestamp: eightYearsAgo))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway" : "steps", "surface": "paved", "tactile_paving": "yes"], timestamp: twoTwoYearsAgo))

        
    }
    

    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(tactilePavingSteps.isApplicable(element: element))
    }
    
    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(tactilePavingSteps.isApplicable(element: element))
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
