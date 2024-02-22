//
//  OSMConnectionTests.swift
//  osmapiTests
//
//  Created by Naresh Devalapally on 1/21/24.
//

import XCTest
@testable import osmapi
import CoreLocation

final class OSMConnectionTests: XCTestCase {
    
    let posmTestNode = "31419"
    let osmTestNode = "4316662656"
    let posmTestWay = "4305301937"
    
    let posmConfig = OSMConfig.testOSM
    let posmCreds = OSMLogin.testOSM
    var posmConnection : OSMConnection?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        posmConnection = OSMConnection(config: posmConfig,userCreds: posmCreds)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testConnection() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to get some data")
        osmConnection.getChangesets2 { result in
            switch result {
            case .success(let responses):
                XCTAssert(responses is OSMChangesetResponse)
            case .failure(let err):
                XCTFail("Error occured while getting message")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        
    }
    func testGetNode() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to get node details")
        osmConnection.getNode(id: osmTestNode) { (result : Result<OSMNodeResponse, Error>) in
            switch result {
            case .success(let nodeResponse):
                let element = nodeResponse.elements.first
                XCTAssertEqual(element!.id, Int(self.osmTestNode))
            case .failure(let error):
                XCTFail("Failed while getting the node")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testGetWay() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to get node details")
        osmConnection.getWay(id: posmTestWay) { (result : Result<OSMWayResponse, Error>) in
            switch result {
            case .success(let nodeResponse):
                let element = nodeResponse.elements.first
                XCTAssertEqual(element!.id, Int(self.posmTestWay))
            case .failure(let error):
                XCTFail("Failed while getting the node")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testChangesetOpen() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to open changeset")
        osmConnection.openChangeSet {result in
            switch result {
            case .success(let changesetId):
                XCTAssert(changesetId != 0)
            case .failure(let error):
               XCTFail("Failed to create changeset")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        // Open changeset
        // add your edits -> Node edit, way edit
        // bulk edit -> changesetUpload -> Python version is used some
        // close changeset
        // onlaunch, get bbox, add some delta [-[]-], get data, insert into db, generate quests from db elements,
        // display on the map -> 1
        // answer is done -> 2,
        // create db element (changeset, node), do a sync of changesets
        // go through each changeset and upload them (open, upload, close)
        
    }
    func testChangesetClose() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to open changeset")
        osmConnection.closeChangeSet(id: "146538436") {_ in 
            expectation.fulfill()
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
    
    // MARK: POSM tests go here
    func testPOSMNode() throws {
        let expectation = expectation(description: "Expect to get node details")
        posmConnection?.getNode(id: self.posmTestNode) { (result : Result<OSMNodeResponse, Error>) in
            switch result {
            case .success(let nodeResponse):
                let element = nodeResponse.elements.first
                XCTAssertEqual(element!.id, Int(self.posmTestNode))
            case .failure(let error):
                XCTFail("Failed while getting the node")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testGetUserChangesets() throws {
        let expectation = expectation(description: "Expect to get changeset details")
        posmConnection?.getChangesets2(completion: { result in
            switch result {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error)
            }
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testPosmOpenChangeset() throws{
        let expectation = expectation(description: "Expect to open changeset")
        posmConnection?.openChangeSet {result in
            switch result {
            case .success(let changesetId):
                XCTAssert(changesetId != 0)
                XCTAssertEqual(self.posmConnection?.currentChangesetId, changesetId)
            case .failure(let error):
               XCTFail("Failed to create changeset")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testPosmCloseChangeset() throws {
        let changesetId = "67"
        let expectation = expectation(description: "Expect to open changeset")
        posmConnection?.closeChangeSet(id: changesetId) {_ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testPosmUpdateNode() throws {
        let expectation = expectation(description: "Expect to update the node")
        let newChangeset = "59"
        let updatedTags = ["highway":"footway","kerb":"lowered"]
        posmConnection?.getNode(id: posmTestNode, { (result : Result<OSMNodeResponse, Error>) in
            switch result{
            case .success(let nodeResponse):
                var firstNode = nodeResponse.elements.first
                firstNode?.changeset = Int(newChangeset)!
                self.posmConnection?.updateNode(node: &firstNode!, tags:  updatedTags, completion: { (result2: Result<Int,Error>) in
                    switch result2 {
                    case .success(let versionNumber):
                        print(versionNumber)
                    case .failure(let error):
                        print(error)
                    }
                    expectation.fulfill()
                })
                
            case .failure(let error):
                XCTFail("Failed to fetch the node")
            }
        })
        
        waitForExpectations(timeout: 12)
    }
    
    func testPosmUpdateWay() throws {
        let expectation = expectation(description: "Expect to update the node")
        let newChangeset = "58"
        let updatedTags = ["name":"Test street"]
        posmConnection?.getWay(id: posmTestWay, { (result : Result<OSMWayResponse, Error>) in
            switch result{
            case .success(let wayResponse):
                var firstWay = wayResponse.elements.first
                firstWay?.changeset = Int(newChangeset)!
                self.posmConnection?.updateWay(way: &firstWay!, tags:  updatedTags, completion: { (result2: Result<Int,Error>) in
                    switch result2 {
                    case .success(let versionNumber):
                        print(versionNumber)
                    case .failure(let error):
                        print(error)
                    }
                    expectation.fulfill()
                })
                
            case .failure(let error):
                XCTFail("Failed to fetch the node")
            }
        })
        
        waitForExpectations(timeout: 12)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    func testGetUserDataWithId() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to get user details")
        osmConnection.getUserDetailsWithId(id: "20018") { result in
            switch result {
            case .success(let userDataResponse):
                let user = userDataResponse.user.id
                XCTAssertEqual(user, 20018)
            case .failure(let error):
                XCTFail("Failed while getting the user details: \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    func testGetUserData() throws {
        let osmConnection = self.posmConnection
        let expectation = expectation(description: "Expect to get user details")
        osmConnection?.getUserDetails() { result in
            switch result {
            case .success(let userDataResponse):
                let user = userDataResponse.user.id
                XCTAssertEqual(user, 20018)
            case .failure(let error):
                XCTFail("Failed while getting the user details: \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 12)
    }
    func testGetMapData() throws {
        let osmConnection = self.posmConnection
        let expectation = expectation(description: "Expect to get map data details from bbox")
        let centralLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco coords
        let distance = 100
        let boundingCoordinates = centralLocation.boundingCoordinates(distance: CLLocationDistance(distance))
        print("Left:", boundingCoordinates.left.coordinate.longitude)
        print("Bottom:", boundingCoordinates.bottom.coordinate.latitude)
        print("Right:", boundingCoordinates.right.coordinate.longitude)
        print("Top:", boundingCoordinates.top.coordinate.latitude)

        osmConnection?.getOSMMapData(left:boundingCoordinates.left.coordinate.longitude , bottom:boundingCoordinates.bottom.coordinate.latitude , right:boundingCoordinates.right.coordinate.longitude , top:boundingCoordinates.top.coordinate.latitude ) { result in
            switch result {
            case .success(let mapData):
                let response = mapData.elements.count
                print(response)
            case .failure(let error):
                XCTFail("Failed while getting the map data details: \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 15)
    }
    
    func testFetchMapData() throws {
        let osmConnection = self.posmConnection
        let expectation = expectation(description: "Expect to get map data details from bbox")
        let centralLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco coords
        let distance = 100
        let boundingCoordinates = centralLocation.boundingCoordinates(distance: CLLocationDistance(distance))
        print("Left:", boundingCoordinates.left.coordinate.longitude)
        print("Bottom:", boundingCoordinates.bottom.coordinate.latitude)
        print("Right:", boundingCoordinates.right.coordinate.longitude)
        print("Top:", boundingCoordinates.top.coordinate.latitude)

        osmConnection?.fetchMapData(left:boundingCoordinates.left.coordinate.longitude , bottom:boundingCoordinates.bottom.coordinate.latitude , right:boundingCoordinates.right.coordinate.longitude , top:boundingCoordinates.top.coordinate.latitude ) { result in
            switch result {
            case .success(let mapData):
//                let response = mapData.elements.count
                print(mapData.count)
                print(mapData.keys)
                print(mapData.first?.value)
            case .failure(let error):
                XCTFail("Failed while getting the map data details: \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 15)
    }
}

extension CLLocation {
    // Calculate bounding box points given a distance in meters
    func boundingCoordinates(distance: CLLocationDistance) -> (left: CLLocation, bottom: CLLocation, right: CLLocation, top: CLLocation) {
        // Earth radius in meters
        let earthRadius = 6_371_000.0

        // Convert distance to radians
        let latRadians = distance / earthRadius
        let lonRadians = distance / (earthRadius * cos(Double.pi * self.coordinate.latitude / 180.0))
        let latDegrees = latRadians * 180.0 / Double.pi
        let lonDegrees = lonRadians * 180.0 / Double.pi

        // Calculate bounding box coordinates
        let left = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude - lonDegrees)
        let bottom = CLLocation(latitude: self.coordinate.latitude - latDegrees, longitude: self.coordinate.longitude)
        let right = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude + lonDegrees)
        let top = CLLocation(latitude: self.coordinate.latitude + latDegrees, longitude: self.coordinate.longitude)

        return (left, bottom, right, top)
    }
}
