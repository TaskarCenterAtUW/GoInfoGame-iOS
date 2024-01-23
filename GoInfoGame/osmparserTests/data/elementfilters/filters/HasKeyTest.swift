//
//  HasKeyTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import XCTest

@testable import osmparser

final class HasKeyTest: XCTestCase {
    
    let key = HasKey(key: "name")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testMatches() throws {
        XCTAssertTrue(key.matches(tags: ["name":"yes"]))
        XCTAssertTrue(key.matches(tags: ["name":"no"]))
        XCTAssertFalse(key.matches(tags: ["neme":"yes"]))
        XCTAssertFalse(key.matches(tags: [:]))
        
    }
    func testDescription() throws {
        XCTAssertEqual("name", key.description)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
