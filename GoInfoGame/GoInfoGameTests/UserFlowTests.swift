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
            let nodePredicateFormat = "tags.@count != 0"
            let wayPredicateFormat = "tags.@count != 0 AND polyline.@count > 0"

            let nodesFromStorage = dbInstance.getNodes(NSPredicate(format: nodePredicateFormat))
            let nodeElements = nodesFromStorage.map({$0.asNode()})
        }
        
    }
    
    // Fetches and generates the quests out of the database
    func testUserQuestsGeneration() throws {
        let nodePredicateFormat = "tags.@count != 0"
        let wayPredicateFormat = "tags.@count != 0 AND polyline.@count > 0"
        
        let nodesFromStorage = dbInstance.getNodes(NSPredicate(format: nodePredicateFormat))
        print(nodesFromStorage.count)
        let waysFromStorage = dbInstance.getWays(NSPredicate(format: wayPredicateFormat))
        
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
    //    func testChangesetCreation() throws {
    //        // Get one node element
    //        // Add a tag and see if we can create an element
    //        guard let oneNode = dbInstance.getNodes().first else {
    //            XCTFail("No nodes available")
    //            return
    //        }
    //        let nodeId = oneNode.id
    //        let addedTags = ["lit":"yes"]
    //        let changedNode = dbInstance.addNodeTags(id: String(nodeId), tags: addedTags)
    //        // Create a changeset
    //        let newChangeset = dbInstance.createChangeset(id: nodeId, type: .node, tags: addedTags)
    //        // Need to figure out the id of the changeset
    //        XCTAssertEqual(newChangeset?.elementType, .node)
    //        XCTAssertEqual(newChangeset?.elementId, String(nodeId))
    //    }
    
    
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
                if let node  = dbInstance.getNode(id: Int(changeset.elementId) ?? 0) {
                    XCTAssert(node.tags.keys.contains("width"))
                    // Publish the node here.
                    let osmConnection = OSMConnection()
                    osmConnection.openChangeSet(createdByTag: "") { result in
                        switch result {
                        case .success(let changesetId):
                            //                            DispatchQueue.main.async {
                            //                                // your code here
                            //                                self.dbInstance.assignChangesetId(obj: changeset.id, changesetId: changesetId)
                            //                            }
                            
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
        
        var cancellables: Set<AnyCancellable> = []
        
        let expectation = XCTestExpectation(description: "Login successful")
        
        let testingTagKey: String = "Testing"
        let testingTagValue: String = "testQuestUndoFlow"
        let workspaceID: Int = 380 // 380 workspace id is for Medina City Test under Test Project Group 1
        let nodeID: Int = 301834 // Before running this test case, make sure no gig tags are added to the node.
        
        DatabaseConnector.shared.clearDB()
        
        // 1. login
        let loginViewModel = PosmLoginViewModel()
        loginViewModel.username = "prateekan6@gmail.com"
        loginViewModel.password = "Test@1234"
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
                        initialViewModel.fetchLongQuestsFor(workspaceId: "\(workspaceID)") { result, string, workspace  in
                            XCTAssert(result)
                            guard let ws = workspace else {
                                XCTFail("Workspace not available")
                                expectation.fulfill()
                                return
                            }

                            let mapViewModel = MapViewModel(workspace: ws)
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
                                       let element = DatabaseConnector.shared.getNode(id: nodeID) {
                                        let tags = element.tags
                                        XCTAssert(tags[testingTagKey] != testingTagValue, "Testing tag is already present")
                                        
                                        // 4. update node tags
                                        let newTestingTags = [testingTagKey: testingTagValue]
                                        if let lognFormQuest = node.displayUnit.parent as? LongElementQuest {
                                            lognFormQuest.updateTags(id: node.id, questType: lognFormQuest.elementType, tags: newTestingTags, type: .node, iconName: lognFormQuest.iconName)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                                // 9. get the node tags and compare
                                                self?.getNodeTags(id: nodeID, workspaceId: workspaceID, completion: { result in
                                                    switch result {
                                                    case .failure(let error):
                                                        XCTFail("\(error)")
                                                        expectation.fulfill()
                                                    case .success(let tags):
                                                        XCTAssert(tags[testingTagKey] == testingTagValue, "Testing tag is not present")
                                                        XCTAssertEqual(tags["ext:gig_complete"], "yes","Gig complete tag not preset")

                                                        // 10. undo the node tags
                                                        DispatchQueue.main.async {
                                                            let undoItems: [UndoItem] = MapUndoManager.shared.getUndoItems()
                                                            let undoItem = undoItems.first { (item: UndoItem) -> Bool in
                                                                item.elementId == nodeID && item.type == .node
                                                            }
                                                            if let undoItem = undoItem  {
                                                                MapUndoManager.shared.undo(for: undoItem.id)
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                                                    // 11. get the node tags and copare
                                                                    self?.getNodeTags(id: nodeID, workspaceId: workspaceID, completion: { result in
                                                                        switch result {
                                                                        case .failure(let error):
                                                                            XCTFail("\(error)")
                                                                            expectation.fulfill()
                                                                        case .success(let tags):
                                                                            XCTAssert(tags[testingTagKey] == nil, "Testing tag is present")
                                                                            XCTAssertEqual(tags["ext:gig_complete"], nil, "Gig complete tag preset")
                                                                        }
                                                                        expectation.fulfill()
                                                                    })
                                                                }
                                                            }
                                                        }
                                                    }
                                                })
                                            }
                                        } else {
                                            XCTAssert(false, "long quest not found")
                                            expectation.fulfill()
                                        }
                                        
                                    } else  {
                                        XCTAssert(false, "No node found") // Before running this test case, make sure no gig tags are added to the node.
                                        expectation.fulfill()
                                    }
                                }
                                .store(in: &cancellables)
                            mapViewModel.fetchOSMDataFor(from: .currentLocation(location: location))
                        }
                    }
                    .store(in: &cancellables)
                
                let workspacesLocation = CLLocationCoordinate2D(latitude: 47.62619, longitude: -122.24255)
                initialViewModel.fetchWorkspacesList(location: workspacesLocation)
            }
            .store(in: &cancellables)
        loginViewModel.performLogin(for: .development)
        wait(for: [expectation], timeout: 50.0)
    }
    
    
    @MainActor
    func testMultiQuestAnswerWithUndo() {
        // 1. login
        // 2. Fetching Workspaces
        // 3. Selecting one workspace (hardcoded to 380)
        // 4. Fetching Longquests
        // 5. Loading elements
        // 6. Selecting couple node (hardcoded to 301833, 301835, 301836)
        // 7. validating is test tag exists
        // 8. updating tag with test tags (Hardcoded tags)
        // 9. get the node tags and compare
        // 10. undo the node tags
        // 11. get the node tags and compare
        
        var cancellables: Set<AnyCancellable> = []
        
        let expectation = XCTestExpectation(description: "Login successful")
        
        let testingTagKey: String = "Testing"
        let testingTagValue: String = "testMultiQuestAnswer"
        let workspaceID: Int = 380 // 380 workspace id is for Medina City Test under Test Project Group 1
        let nodeIDs: [Int] = [301833, 301836]
        
        DatabaseConnector.shared.clearDB()
        
        // 1. login
        let loginViewModel = PosmLoginViewModel()
        loginViewModel.username = "prateekan6@gmail.com"
        loginViewModel.password = "Test@1234"
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
                        initialViewModel.fetchLongQuestsFor(workspaceId: "\(workspaceID)") { result, string, workspace in
                            XCTAssert(result)
                            guard let ws = workspace else {
                                XCTFail("Workspace not available")
                                expectation.fulfill()
                                return
                            }

                            // 5. Loading elements
                            let mapViewModel = MapViewModel(workspace: ws)
                            mapViewModel.isMultiSelectModeEnabled = true
                            let location = CLLocationCoordinate2D(latitude: 47.62619, longitude: -122.24255)
                            mapViewModel.$isLoading
                                .dropFirst(2)
                                .receive(on: DispatchQueue.main)
                                .sink { _ in
                                    cancellables.first?.cancel()
                                    cancellables.removeFirst()
                                    
                                    // 6. Selecting couple node (hardcoded to 301833, 301835, 301836)
                                    let nodes = AppQuestManager.shared.fetchQuestsFromDB().filter({ element in
                                        nodeIDs.contains(Int(element.id))
                                    })
                                    XCTAssertEqual(nodeIDs.count, nodeIDs.count, "All nodes not found.")
                                    
                                    let displayUnitAnnotations = nodes.map { $0.annotation }
                                    
                                    
                                    displayUnitAnnotations.forEach { annotation in
                                        mapViewModel.selectedAnnotaions.insert(annotation)
                                    }
                                    
                                    let displayUnit = mapViewModel.getSelectedQuest()
                                    if let longElementQuest = displayUnit?.parent as? LongElementQuest,
                                       let form = longElementQuest.internalForm as? LongForm {
                                        form.action?([testingTagKey : testingTagValue])
                                    } else {
                                        XCTFail("LongElementQuest UI component not found")
                                        expectation.fulfill()
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                        // 9. get the node tags and compare
                                    let group = DispatchGroup()
                                        group.enter()
                                        self?.getNodeTags(id: nodeIDs.first ?? 0, workspaceId: workspaceID, completion: { result in
                                            switch result {
                                            case .failure(let error):
                                                XCTFail("\(error)")
                                            case .success(let tags):
                                                XCTAssert(tags[testingTagKey] == testingTagValue, "Testing tag is not present")
                                                XCTAssertEqual(tags["ext:gig_complete"], "yes","Gig complete tag not preset")
                                            }
                                            group.leave()
                                        })
                                        
                                        group.enter()
                                        self?.getNodeTags(id: nodeIDs.last ?? 0, workspaceId: workspaceID, completion: { result in
                                            switch result {
                                            case .failure(let error):
                                                XCTFail("\(error)")
                                            case .success(let tags):
                                                XCTAssert(tags[testingTagKey] == testingTagValue, "Testing tag is not present")
                                                XCTAssertEqual(tags["ext:gig_complete"], "yes","Gig complete tag not preset")
                                            }
                                            group.leave()
                                        })
                                        
                                        group.notify(queue: .main) {
                                            // 10. undo the node tags
                                            let undogroup = DispatchGroup()

                                            let firstNodeID: Int = nodeIDs.first ?? 0
                                            let undoItems1: [UndoItem] = MapUndoManager.shared.getUndoItems()
                                            let undoItem1 = undoItems1.first { (item: UndoItem) -> Bool in
                                                item.elementId == firstNodeID && item.type == .node
                                            }
                                            if let undoItem = undoItem1  {
                                                undogroup.enter()
                                                MapUndoManager.shared.undo(for: undoItem.id)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                                    // 11. get the node tags and compare
                                                    self?.getNodeTags(id: nodeIDs.first ?? 0, workspaceId: workspaceID, completion: { result in
                                                        switch result {
                                                        case .failure(let error):
                                                            XCTFail("\(error)")
                                                            expectation.fulfill()
                                                        case .success(let tags):
                                                            XCTAssert(tags[testingTagKey] == nil, "Testing tag is present")
                                                            XCTAssertEqual(tags["ext:gig_complete"], nil, "Gig complete tag preset")
                                                        }
                                                        undogroup.leave()
                                                    })
                                                }
                                            }
                                            
                                            let lastNodeID: Int = nodeIDs.last ?? 0
                                            let undoItems2: [UndoItem] = MapUndoManager.shared.getUndoItems()
                                            let undoItem2 = undoItems2.first { (item: UndoItem) -> Bool in
                                                item.elementId == lastNodeID && item.type == .node
                                            }
                                            if let undoItem = undoItem2  {
                                                undogroup.enter()
                                                MapUndoManager.shared.undo(for: undoItem.id)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                                    // 11. get the node tags and compare
                                                    self?.getNodeTags(id: nodeIDs.last ?? 0, workspaceId: workspaceID, completion: { result in
                                                        switch result {
                                                        case .failure(let error):
                                                            XCTFail("\(error)")
                                                            expectation.fulfill()
                                                        case .success(let tags):
                                                            XCTAssert(tags[testingTagKey] == nil, "Testing tag is present")
                                                            XCTAssertEqual(tags["ext:gig_complete"], nil, "Gig complete tag preset")
                                                        }
                                                        undogroup.leave()
                                                    })
                                                }
                                            }
                                            
                                            undogroup.notify(queue: .main) {
                                                expectation.fulfill()
                                            }
                                        }
                                    }
                                }
                                .store(in: &cancellables)
                            mapViewModel.fetchOSMDataFor(from: .currentLocation(location: location))
                        }
                    }
                    .store(in: &cancellables)
                let workspacesLocation = CLLocationCoordinate2D(latitude: 47.62619, longitude: -122.24255)
                initialViewModel.fetchWorkspacesList(location: workspacesLocation)
            }
            .store(in: &cancellables)
        loginViewModel.performLogin(for: .development)
        wait(for: [expectation], timeout: 50.0)
        
    }
    
    func getNodeTags(id: Int, workspaceId: Int, completion: @escaping (Result<[String: String], Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://osm.workspaces-stage.sidewalks.washington.edu/api/0.6/node/\(id).json")!,timeoutInterval: Double.infinity)
        request.addValue("\(workspaceId)", forHTTPHeaderField: "X-Workspace")
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                completion(.failure(error ?? NSError(domain: "failed", code: 101, userInfo: nil)))
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print(jsonObject)
                    if let element = (jsonObject["elements"] as? [[String: Any]])?.first,
                       let tags = element["tags"] as? [String : String] {
                        completion(.success(tags))
                    } else {
                        completion(.failure(NSError(domain: "tags not found", code: 101, userInfo: nil)))
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
        
    }
}
