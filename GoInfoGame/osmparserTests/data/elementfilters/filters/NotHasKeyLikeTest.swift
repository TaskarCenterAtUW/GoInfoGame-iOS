//
//  NotHasKeyLikeTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import XCTest
@testable import osmparser

final class NotHasKeyLikeTest: XCTestCase {
    
    let parser = NotHasKeyLike(key: "n.[ms]e")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMatches() throws {
        XCTAssertFalse(parser.matches(tags: ["name": "adsf"]))
        XCTAssertFalse(parser.matches(tags: ["nase": "fefff"]))
        XCTAssertFalse(parser.matches(tags: ["neme": "no"]))
        XCTAssertTrue(parser.matches(tags: ["a name yo": "no"]))
        XCTAssertFalse(parser.matches(tags: ["n(se": "no"]))
        XCTAssertTrue(parser.matches(tags: [:]))
        
    }
    
    func testDescription() throws {
        XCTAssertEqual("!~n.[ms]e", parser.description)
    }
   
    
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
