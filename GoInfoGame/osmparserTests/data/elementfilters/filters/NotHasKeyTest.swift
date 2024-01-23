//
//  NotHasKeyTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import XCTest
@testable import  osmparser

final class NotHasKeyTest: XCTestCase {
    
    let c = NotHasKey(key: "name")
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testMatches() throws {
        XCTAssertFalse(c.matches(tags: ["name":"yes"]))
        XCTAssertFalse(c.matches(tags: ["name":"no"]))
        XCTAssertTrue(c.matches(tags: ["neme":"no"]))
        XCTAssertTrue(c.matches(tags: [:]))
    }
    
    func testDescription() throws {
        XCTAssertEqual("!name", c.description)
    }

//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        // Any test you write for XCTest can be annotated as throws and async.
//        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
//        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
//    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
