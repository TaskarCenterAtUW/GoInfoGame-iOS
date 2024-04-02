//
//  WorkspacesApiManagerTests.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 4/1/24.
//

@testable import GoInfoGame

import XCTest

final class WorkspacesApiManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let workspacesAPI = WorkspacesApiManager.shared
        let expec = expectation(description: "Fetches the workspaces around user")
        
        
        workspacesAPI.fetchWorkspaces(lat:"",lon:""){result in
            switch result {
            case .success(let workspacesResponse):
                print(workspacesResponse)
                print(workspacesResponse.workspaces)
                
            case .failure(let error):
                print(error)
                
            }
            expec.fulfill()
        }
        waitForExpectations(timeout: 15)
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
