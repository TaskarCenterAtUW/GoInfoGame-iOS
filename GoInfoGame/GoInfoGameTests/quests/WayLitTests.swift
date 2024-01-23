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
