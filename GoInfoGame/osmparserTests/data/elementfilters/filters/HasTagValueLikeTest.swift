//
//  HasTagValueLikeTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/4/24.
//

import XCTest
@testable import osmparser
final class HasTagValueLikeTest: XCTestCase {
    
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMatchesLikeDot() {
        let f = HasTagValueLike(key: "highway", value: ".esidential")
        XCTAssertTrue(f.matches(tags: ["highway":"residential"]))
        XCTAssertTrue(f.matches(tags: ["highway":"wesidential"]))
        XCTAssertFalse(f.matches(tags: ["highway":"rresidential"]))
        XCTAssertFalse(f.matches(tags: [:]))
    }
    func testMatchesLikeOr () {
        let f = HasTagValueLike(key: "highway", value: "residential|unclassified")
        XCTAssertTrue(f.matches(tags: ["highway":"residential"]))
        XCTAssertTrue(f.matches(tags: ["highway":"unclassified"]))
        XCTAssertFalse(f.matches(tags: ["highway":"blub"]))
        XCTAssertFalse(f.matches(tags: [:]))
    }
    
    func testMatchesLikeCharacterClass () {
        let f = HasTagValueLike(key: "maxspeed", value: "([1-9]|[1-2][0-9]|3[0-5]) mph")
        XCTAssertTrue(f.matches(tags: ["maxspeed":"1 mph"]))
        XCTAssertTrue(f.matches(tags: ["maxspeed":"5 mph"]))
        XCTAssertTrue(f.matches(tags: ["maxspeed":"15 mph"]))
        XCTAssertTrue(f.matches(tags: ["maxspeed":"25 mph"]))
        XCTAssertTrue(f.matches(tags: ["maxspeed":"35 mph"]))
        XCTAssertFalse(f.matches(tags: ["maxspeed":"40 mph"]))
        XCTAssertFalse(f.matches(tags: ["maxspeed":"135 mph"]))
        XCTAssertFalse(f.matches(tags: [:]))
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
