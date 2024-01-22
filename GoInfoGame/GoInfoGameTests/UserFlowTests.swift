//
//  UserFlowTests.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 1/22/24.
//

import XCTest
@testable import GoInfoGame
@testable import SwiftOverpassAPI

/**
 Used to test the flow of information
  This fetches the information and sends things down
 */
final class UserFlowTests: XCTestCase {

    let opManager = OverpassRequestManager()
    
    let dbInstance = DatabaseConnector.shared
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let expec = expectation(description: "Fetches the elements from Overpass Manager and stores in Database")
        let kirklandBBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
        opManager.fetchElements(fromBBox: kirklandBBox) { fetchedElements in
            // Get the count of nodes and ways
            let allValues = fetchedElements.values
            
            let nodes = allValues.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
            let ways = allValues.filter({$0  is OPWay}).filter({!$0.tags.isEmpty})
            self.dbInstance.saveElements(nodes) // Save nodes
//            let nodesFromStorage = dbInstance.getNodes()
//            XCTAssertEqual(nodes.count, nodesFromStorage.count)
            
            expec.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testDataInserts() throws {
        let nodesFromStorage = dbInstance.getNodes()
        XCTAssert(nodesFromStorage.count > 0)
        // Get the Nodes from the above
        let testQuest = TestQuest()
        for singleNode in nodesFromStorage {
//            testQuest.isApplicable(element: singleNode)
        }
        
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
