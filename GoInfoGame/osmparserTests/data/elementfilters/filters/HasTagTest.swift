//
//  HasTagTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import XCTest
@testable import osmparser

final class HasTagTest: XCTestCase {
    
    let c = HasTag(key: "highway", value: "residential")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMatches() throws {
        XCTAssertTrue(c.matches(tags: ["highway":"residential"]))
        XCTAssertFalse(c.matches(tags: ["highway":"residental"]))
        XCTAssertFalse(c.matches(tags: ["hipway":"residential"]))
        XCTAssertFalse(c.matches(tags: [:]))
    }
    
    func testDescription() throws {
        XCTAssertEqual("highway = residential", c.description)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
