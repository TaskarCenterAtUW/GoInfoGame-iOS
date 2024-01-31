//
//  DatasyncManagerTests.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 1/29/24.
//

import XCTest
@testable import GoInfoGame

final class DatasyncManagerTests: XCTestCase {

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
    }
    
    func testOpenChangeset() async throws {
        let dbSyncManager  = DatasyncManager.shared
        let result = await dbSyncManager.openChangeset()
        switch result {
        case .success(let changesetId):
            print("Got the chnageset ID")
            print(changesetId)
        case .failure(let error):
            XCTFail("Failed to get the changesetID")
        }
    }
    
    func testDataSync() async throws {
        let dbSyncManager  = DatasyncManager.shared
        await dbSyncManager.syncData()
//        await dbSyncManager.syncDataDummy()
        
    }
    
    func testDualDataSync()  async throws {
        // TO be done. Need to check two calls on the same thing.
        let dbSyncManager  = DatasyncManager.shared
        Task {
           await dbSyncManager.syncData()
        }
        Task {
            await dbSyncManager.syncData()
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}