//
//  UserFlowTests.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 1/22/24.
//

import XCTest
@testable import GoInfoGame
//@testable import SwiftOverpassAPI
@testable import osmparser
@testable import osmapi
import Combine
import CoreLocation

/**
 Used to test the flow of information
  This fetches the information and sends things down 
 */
final class UserFlowTests: XCTestCase {

//    let opManager = OverpassRequestManager()
    
    let dbInstance = DatabaseConnector.shared
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
//       seedData()
    }
    
    func seedData() {
//        let expec = expectation(description: "Fetches the elements from Overpass Manager and stores in Database")
//        let kirklandBBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
//        opManager.fetchElements(fromBBox: kirklandBBox) { fetchedElements in
//            // Get the count of nodes and ways
//            let allValues = fetchedElements.values
//            
//            let nodes = allValues.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
//            let ways = allValues.filter({$0  is OPWay}).filter({!$0.tags.isEmpty})
//            let allElements = allValues.filter({!$0.tags.isEmpty})
//            self.dbInstance.saveElements(allElements) // Save all where there are tags
//            expec.fulfill()
//        }
//        
//        waitForExpectations(timeout: 10)
    }
    
    func testDataInserts() throws {
//        let nodesFromStorage = dbInstance.getNodes()
//        let waysFromStorage = dbInstance.getWays()
//        XCTAssert(nodesFromStorage.count > 0)
//        // Get the Nodes from the above
//        let nodeElements = nodesFromStorage.map({$0.asNode()})
//        let wayElements = waysFromStorage.map({$0.asWay()})
//        let testQuest = TestQuest()
//        var applicableElements: [Element] = []
//        for singleNode in nodeElements {
////            testQuest.isApplicable(element: singleNode)
//            let isApplicable = testQuest.isApplicable(element: singleNode)
//            if (isApplicable){
//                applicableElements.append(singleNode)
//                print(singleNode.tags)
//            }
//        }
//        for singleWay in wayElements {
//            let isApplicable = testQuest.isApplicable(element: singleWay)
//            if (isApplicable){
//                applicableElements.append(singleWay)
//                print(singleWay.tags)
//            }
//        }
//        print(applicableElements.count)
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
        
        self.measure { // 3106 nodes -> 46 seconds after optimization..0.5seconds
            // Get the quests for ways
            for node in nodeElements {
                // Get the quests and try to iterate
                for quest in allQuests {
//                    if quest.filter.isEmpty {continue} // Ignore quest
                    // isApplicable API is not being used and is not available now.
//                    if quest.isApplicable(element: node){
//                        // Create a duplicate of the quest
//                        nodeQuests.append(quest)
//                        print(quest)
//                        break
//                    }
                }
            }
            print(nodeQuests.count)
            
            
            
            //        print(nodeQuests.count)
            for way in wayElements{
                for quest in allQuests {
//                    if quest.filter.isEmpty {continue} // Ignore quest
//                    isApplicable API is not being used and is not available now.
//                    if quest.isApplicable(element: way){
//                        // Create a duplicate of the quest
//                        wayQuests.append(quest)
//                        print(quest)
//                        break
//                    }
                }
            }
            print(wayQuests.count)
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // Tests if we can add an element in the directory
    func testChangesetCreation() throws {
        // Get one node element
        // Add a tag and see if we can create an element
        guard let oneNode = dbInstance.getNodes().first else {
            XCTFail("No nodes available")
            return
        }
        let nodeId = oneNode.id
        let addedTags = ["lit":"yes"]
        let changedNode = dbInstance.addNodeTags(id: String(nodeId), tags: addedTags)
        // Create a changeset
        let newChangeset = dbInstance.createChangeset(id: String(nodeId), type: .node, tags: addedTags, isUndo: false )
        // Need to figure out the id of the changeset
        XCTAssertEqual(newChangeset?.elementType, .node)
        XCTAssertEqual(newChangeset?.elementId, String(nodeId))
    }
    
    
    func testChangesetFetch() throws {
        let changesets = dbInstance.getChangesets(synced: true)
        XCTAssert(changesets.count != 0)
        // Get the changesetId of the first one
        for changeset in changesets {
            print(changeset.changesetId)
        }
    }
    
    func testPublishChangeset() throws {
        
        let expectation = expectation(description: "Expect to create changesetID")
        // Get the changesets
        let changesets = dbInstance.getChangesets()
        // Get the elements based on the type
        for changeset in changesets {
            // Get the element type
            if changeset.elementType == .node {
                // Get the node
                if let node  = dbInstance.getNode(id: Int(changeset.elementId) ?? 0, version: .original) {
                    XCTAssert(node.tags.keys.contains("width"))
                    // Publish the node here.
                    let osmConnection = OSMConnection()
                    osmConnection.openChangeSet(createdByTag: "") { result in
                        switch result {
                        case .success(let changesetId):
                            DispatchQueue.main.async {
                              // your code here
                                self.dbInstance.assignChangesetId(obj: changeset.id, changesetId: changesetId)
                            }
                            
                            print("opened successfully")
                        case .failure(let error):
                            print("Failed to open ")
                        }
                        expectation.fulfill()
                    }
                }
                else{
                    XCTFail("No node obtained for changeset ")
                }
            }
        }
        waitForExpectations(timeout: 10)
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

    
    @MainActor
    func testQuestUndoFlow() {
        // 1. login
        // 2. Fetching Workspaces
        // 3. Selecting one workspace (hardcoded to 380)
        // 4. Fetching Longquests
        // 5. Loading elements
        // 6. Selecting one node (hardcoded to 301834)
        // 7. validating is test tag exists
        // 8. updating tag with test tags (Hardcoded tags)
        
        // 9. get the node tags and compare
        // 10. undo the node tags
        // 11. get the node tags and copare
        // 12. logout
        
        var cancellables: Set<AnyCancellable> = []
        
        let expectation = XCTestExpectation(description: "Login successful")
        
        let testingTagKey: String = "Testing"
        let testingTagValue: String = "testQuestUndoFlow"
        let workspaceID: Int = 380 // 380 workspace id is for Medina City Test under Test Project Group 1
        let nodeID: Int = 301834
        
        // 1. login
        let loginViewModel = PosmLoginViewModel()
        loginViewModel.username = "prateekan6@gmail.com"
        loginViewModel.password = "Test@1234"
        DatabaseConnector.shared.clearDB()
        loginViewModel.$isLoginSuccess
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { isLoggedIn in
                XCTAssertTrue(isLoggedIn)
                cancellables.first?.cancel()
                cancellables.removeFirst()
                
                // 2. fetching workspaces
                let initialViewModel = InitialViewModel()
                initialViewModel.$isLoading
                    .dropFirst()
                    .receive(on: DispatchQueue.main)
                    .sink { isloading in
                        cancellables.first?.cancel()
                        cancellables.removeFirst()
                        
                        // 3. select the workspace
                        let workspaceId: String = "\(workspaceID)"
                        _ = GoInfoGame.KeychainManager.save(key: "workspaceID", data: workspaceId)
                        
                        // 4. get the node tages
                        initialViewModel.fetchLongQuestsFor(workspaceId: "\(workspaceID)") { result, string in
                            XCTAssert(result)
                            
                            let mapViewModel = MapViewModel()
                            let location = CLLocationCoordinate2D(latitude: 47.62619, longitude: -122.24255)
                            mapViewModel.$isLoading
                                .dropFirst(2)
                                .receive(on: DispatchQueue.main)
                                .sink { _ in
                                    cancellables.first?.cancel()
                                    cancellables.removeFirst()
                                    
                                    if let node = AppQuestManager.shared.fetchQuestsFromDB().first(where: { element in
                                        element.id == nodeID
                                    }),
                                       let element = DatabaseConnector.shared.getNode(id: nodeID, version: .original) {
                                        let tags = element.tags
                                        XCTAssert(tags[testingTagKey] != testingTagValue, "Testing tag is already present")
                                        
                                        // 4. update node tags
                                        let newTestingTags = [testingTagKey: testingTagValue]
                                        if let lognFormQuest = node.displayUnit.parent as? LongElementQuest {
                                            lognFormQuest.updateTags(id: node.id, tags: newTestingTags, type: .node)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                                if let element = DatabaseConnector.shared.getNode(id: nodeID, version: .original) {
                                                    XCTAssert(element.tags[testingTagKey] == testingTagValue, "Testing tag is not updated")
                                                }
                                                expectation.fulfill()
                                            }
                                        } else {
                                            XCTAssert(false, "long quest not found")
                                            expectation.fulfill()
                                        }
                                        
                                    } else  {
                                        XCTAssert(false, "No node found")
                                        expectation.fulfill()
                                    }
                                }
                                .store(in: &cancellables)
                            mapViewModel.fetchOSMDataFor(from: .currentLocation(location: location))
                        }
                    }
                    .store(in: &cancellables)
                
                initialViewModel.fetchWorkspacesList()
            }
            .store(in: &cancellables)
        loginViewModel.performLogin()

        
        wait(for: [expectation], timeout: 25.0)
        
    }
}
