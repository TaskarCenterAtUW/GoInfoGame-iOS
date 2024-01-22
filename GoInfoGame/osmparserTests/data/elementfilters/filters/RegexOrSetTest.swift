//
//  RegexOrSetTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import XCTest
@testable import osmparser

final class RegexOrSetTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testPipesMatch() throws {
        let r = RegexOrSet.from(string: "a|b|c")
        XCTAssertTrue(r.matches(str: "a"))
        XCTAssertTrue(r.matches(str: "b"))
        XCTAssertTrue(r.matches(str: "c"))
        XCTAssertFalse(r.matches(str: "d"))
        XCTAssertFalse(r.matches(str: "a|b"))
        
        
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
