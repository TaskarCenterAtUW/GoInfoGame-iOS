//
//  WayLitTests.swift
//  GoInfoGameTests
//
//  Created by Rajesh Kantipudi on 23/01/24.
//

import XCTest
@testable import GoInfoGame
@testable import osmparser


final class WayLitTests: XCTestCase {

    let dbInstance = DatabaseConnector.shared
    var nodes:[Node] = []
    var ways:[Way] = []
    let wayLit = WayLit()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let nodesFromStorage = dbInstance.getNodes()
        let waysFromStorage = dbInstance.getWays()
        
        nodes = nodesFromStorage.map({$0.asNode()})
        ways = waysFromStorage.map({$0.asWay()})
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFilterString() throws {
        let wayLit = WayLit()
        print(wayLit.filter)
        
    }
    func testQuestFilter() throws {
        let wayLit = WayLit()
        var applicableNodes:[Node] = []
        var applicableWays: [Way] = []
//        self.measure {
            for node in nodes {
                if(wayLit.isApplicable(element: node)){
                    applicableNodes.append(node)
                    print(node.tags)
                }
            }
//        }
       
        
        self.measure {
            for way in ways {
                if(wayLit.isApplicable(element: way)){
                    applicableWays.append(way)
                    print(way.tags)
                }
            }
             
        }
           
        
       
        
        XCTAssert(applicableWays.count > 0)
        XCTAssert(applicableNodes.isEmpty)
        
    }
    
    /** Testing the query
     ways with
             (
               highway ~ residential|living_street|pedestrian
               or highway ~ motorway|motorway_link|trunk|trunk_link|primary|primary_link|secondary|secondary_link|tertiary|tertiary_link|unclassified|service and
               (
                 sidewalk ~ both|left|right|yes|separate
                 or ~"source:maxspeed|zone:traffic|maxspeed:type|zone:maxspeed|maxspeed" ~ ".*:(urban|.*zone.*|nsl_restricted)"
                 or maxspeed <= 60
               )
               or highway ~ footway|cycleway|steps
               or highway = path and (foot = designated or bicycle = designated)
             )
             and
             (
               !lit
               or lit = no and lit older today -8 years
               or lit older today -16 years
             )
             and (access !~ private|no or (foot and foot !~ private|no))
             and indoor != yes
             and ~path|footway|cycleway !~ link
     
     */
    
    func testWayLitQuery() throws {
        let eightYearsAgo = TestQuestUtils.olderThan(years: -8)

        assertIsNotApplicable(element: TestQuestUtils.node(tags: ["" : ""]))
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway":"pedestrian"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway":"pedestrian","access":"no"])) // no access to the path
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway":"pedestrian","indoor":"yes"])) // path is indoor
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway":"pedestrian","footway":"link"]))
        assertIsNotApplicable(element: TestQuestUtils.way(tags: ["highway":"pedestrian","lit":"yes"])) // lit tag already exists
        
        assertIsApplicable(element: TestQuestUtils.way(tags: ["highway": "path", "sidewalk": "separate", "maxspeed": "60", "bicycle": "designated", "lit": "no"], timestamp: eightYearsAgo))
    }

    private func assertIsApplicable(element: Element) {
        XCTAssertTrue(wayLit.isApplicable(element: element))
    }
    
    private func assertIsNotApplicable(element: Element) {
        XCTAssertFalse(wayLit.isApplicable(element: element))
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
