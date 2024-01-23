//
//  HasTagLikeTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/4/24.
//

import XCTest
@testable import osmparser

final class HasTagLikeTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testMatchesRegexKeyAndValue() throws {
        let f = HasTagLike(key: ".ame", value: "y.s")
        XCTAssertTrue(f.matches(tags: ["name":"yes"]))
        XCTAssertTrue(f.matches(tags: ["lame":"yos"]))
        XCTAssertFalse(f.matches(tags: ["lame":"no"]))
        XCTAssertFalse(f.matches(tags: ["good":"yes"]))
        XCTAssertFalse(f.matches(tags: ["neme":"no"]))
        XCTAssertFalse(f.matches(tags: ["names":"yess"]))
        XCTAssertFalse(f.matches(tags: [:]))
    }
    
    func testMatchesExactValueWithoutRegex() throws {
        let f = HasTagLike(key: "shop", value: "cheese")
        XCTAssertTrue(f.matches(tags: ["shop":"cheese"]))
        XCTAssertFalse(f.matches(tags: ["shop":"cheese_frog_swamp"]))
    }
    
    func testMatchPipesList() throws {
        let f = HasTagLike(key: "shop", value: "cheese|greengrocer")
        
        XCTAssertTrue(f.matches(tags: ["shop":"cheese"]))
        XCTAssertTrue(f.matches(tags: ["shop":"greengrocer"]))
        XCTAssertFalse(f.matches(tags: ["shop":"cheese_frog_swamp"]))
        XCTAssertFalse(f.matches(tags: ["shop":"cheese|greengrocer"]))
    }
    
    func testDescription() {
        XCTAssertEqual("~.ame ~ y.s", HasTagLike(key: ".ame", value: "y.s").description)
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

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
