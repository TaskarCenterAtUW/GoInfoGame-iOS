//
//  UserFlowTests.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 1/22/24.
//

import XCTest
@testable import GoInfoGame
@testable import SwiftOverpassAPI
@testable import osmparser
/**
 Used to test the flow of information
  This fetches the information and sends things down
 */
final class UserFlowTests: XCTestCase {

    let opManager = OverpassRequestManager()
    
    let dbInstance = DatabaseConnector.shared
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
//       seedData()
    }
    
    func seedData() {
        let expec = expectation(description: "Fetches the elements from Overpass Manager and stores in Database")
        let kirklandBBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
        opManager.fetchElements(fromBBox: kirklandBBox) { fetchedElements in
            // Get the count of nodes and ways
            let allValues = fetchedElements.values
            
            let nodes = allValues.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
            let ways = allValues.filter({$0  is OPWay}).filter({!$0.tags.isEmpty})
            let allElements = allValues.filter({!$0.tags.isEmpty})
            self.dbInstance.saveElements(allElements) // Save all where there are tags
            expec.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testDataInserts() throws {
        let nodesFromStorage = dbInstance.getNodes()
        let waysFromStorage = dbInstance.getWays()
        XCTAssert(nodesFromStorage.count > 0)
        // Get the Nodes from the above
        let nodeElements = nodesFromStorage.map({$0.asNode()})
        let wayElements = waysFromStorage.map({$0.asWay()})
        let testQuest = TestQuest()
        var applicableElements: [Element] = []
        for singleNode in nodeElements {
//            testQuest.isApplicable(element: singleNode)
            let isApplicable = testQuest.isApplicable(element: singleNode)
            if (isApplicable){
                applicableElements.append(singleNode)
                print(singleNode.tags)
            }
        }
        for singleWay in wayElements {
            let isApplicable = testQuest.isApplicable(element: singleWay)
            if (isApplicable){
                applicableElements.append(singleWay)
                print(singleWay.tags)
            }
        }
        print(applicableElements.count)
    }
    
    func testPerformanceDBFetch() throws {
        self.measure {
            let nodesFromStorage = dbInstance.getNodes()
            let nodeElements = nodesFromStorage.map({$0.asNode()})
        }
        
    }
    
    // Fetches and generates the quests out of the database
    func testUserQuestsGeneration() throws {
        let nodesFromStorage = dbInstance.getNodes()
        print(nodesFromStorage.count)
        let waysFromStorage = dbInstance.getWays()
        
        let nodeElements = nodesFromStorage.map({$0.asNode()})
        let wayElements = waysFromStorage.map({$0.asWay()})
        
        // Get the quests for nodes
        var nodeQuests: [any Quest] = []
        var wayQuests: [any Quest] = []
        let allQuests = QuestsRepository.shared.applicableQuests
        
        self.measure {
            // Get the quests for ways
            for node in nodeElements {
                // Get the quests and try to iterate
                for quest in allQuests {
                    if quest.filter.isEmpty {continue} // Ignore quest
                    if quest.isApplicable(element: node){
                        // Create a duplicate of the quest
                        nodeQuests.append(quest)
                        print(quest)
                        break
                    }
                }
            }
            print(nodeQuests.count)
             
        }
      
//        print(nodeQuests.count)
//        for way in wayElements{
//            for quest in allQuests {
//                if quest.filter.isEmpty {continue} // Ignore quest
//                if quest.isApplicable(element: way){
//                    // Create a duplicate of the quest
//                    wayQuests.append(quest)
//                    print(quest)
//                    break
//                }
//            }
//        }
//        print(wayQuests.count)
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
