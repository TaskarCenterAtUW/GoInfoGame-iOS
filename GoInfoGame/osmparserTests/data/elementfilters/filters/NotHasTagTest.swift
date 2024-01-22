//
//  NotHasTagTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import XCTest
@testable import osmparser

final class NotHasTagTest: XCTestCase {

    let c = NotHasTag(key: "highway", value: "residential")
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMatches() throws {
        XCTAssertFalse(c.matches(tags: ["highway":"residential"]))
        XCTAssertTrue(c.matches(tags: ["highway":"residental"]))
        XCTAssertTrue(c.matches(tags: ["hipway":"residential"]))
        XCTAssertTrue(c.matches(tags: [:]))
    }
    
    func testDesciption() throws {
        XCTAssertEqual("highway != residential", c.description)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
