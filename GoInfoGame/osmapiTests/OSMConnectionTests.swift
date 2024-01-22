//
//  OSMConnectionTests.swift
//  osmapiTests
//
//  Created by Naresh Devalapally on 1/21/24.
//

import XCTest

@testable import osmapi


final class OSMConnectionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
                print(err)
                XCTFail("Error occured while getting message")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        
    }
    func testGetNode() throws {
        let osmConnection = OSMConnection()
        let expectation = expectation(description: "Expect to get node details")
        osmConnection.getNode(id: "4977475294") { (result : Result<OSMNodeResponse, Error>) in
            switch result {
            case .success(let nodeResponse):
                let element = nodeResponse.elements.first
                XCTAssertEqual(element!.id, 4977475294)
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
        osmConnection.getWay(id: "508700858") { (result : Result<OSMWayResponse, Error>) in
            switch result {
            case .success(let nodeResponse):
                let element = nodeResponse.elements.first
                XCTAssertEqual(element!.id, 508700858)
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
        
        osmConnection.openChangeSet {
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
