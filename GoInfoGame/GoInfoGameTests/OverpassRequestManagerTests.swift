//
//  OverpassRequestManagerTests.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 1/21/24.
//

import XCTest

@testable import GoInfoGame
import SwiftOverpassAPI



final class OverpassRequestManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
        /*
         [
                       -122.20866792353317,
                       47.718964653825054
                     ],
                     [
                       -122.20866792353317,
                       47.70312160869372
                     ],
                     [
                       -122.18570621653987,
                       47.70312160869372
                     ],
                     [
                       -122.18570621653987,
                       47.718964653825054
                     ],
                     [
                       -122.20866792353317,
                       47.718964653825054
                     ]
         */
        
    }
    
    func testFetchElements() throws {
        let opManager = OverpassRequestManager()
        let expec = expectation(description: "Fetches the elements from Overpass Manager")
//        let bbox = BBox(minLat: 47.644234213297665, maxLat: 47.648330990799394, minLon: -122.15643268012565, maxLon: -122.15117873022045)
        let kirklandBBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
        opManager.fetchElements(fromBBox: kirklandBBox) { fetchedElements in
            // Get the count of nodes and ways
            let allValues = fetchedElements.values
            
            let nodes = allValues.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
            let ways = allValues.filter({$0  is OPWay}).filter({!$0.tags.isEmpty})
            if(nodes.count > 0){
                if let firstNode = nodes.first as? OPNode {
                    print(firstNode.geometry)
                }
            }
            if (ways.count > 0){
                if let firstWay = ways.first as? OPWay {
                    // Try to get the geometry
                    print(firstWay.geometry)
                }
            }
            expec.fulfill()
        }
        
        waitForExpectations(timeout: 15)
    }
    
    func testStorage() throws {
        let opManager = OverpassRequestManager()
        let expec = expectation(description: "Fetches the elements from Overpass Manager and stores in Database")
        let dbInstance = DatabaseConnector.shared
        
        let kirklandBBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
        opManager.fetchElements(fromBBox: kirklandBBox) { fetchedElements in
            // Get the count of nodes and ways
            let allValues = fetchedElements.values
            
            let nodes = allValues.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
            let ways = allValues.filter({$0  is OPWay}).filter({!$0.tags.isEmpty})
            let allElements = allValues.filter({!$0.tags.isEmpty})
            dbInstance.saveElements(allElements) // Save nodes
            let nodesFromStorage = dbInstance.getNodes()
            let waysFromStorage = dbInstance.getWays()
            XCTAssertEqual(nodes.count, nodesFromStorage.count)
            XCTAssertEqual(ways.count, waysFromStorage.count)
            
            expec.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
