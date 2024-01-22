//
//  NotHasTagLikeTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/4/24.
//

import XCTest
@testable import osmparser

final class NotHasTagLikeTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMatchesRegexKeyAndValue() throws {
        let f = NotHasTagLike(key: ".ame", value: "y.s")
        XCTAssertFalse(f.matches(tags: ["name":"yes"]))
        XCTAssertFalse(f.matches(tags: ["lame":"yos"]))
        XCTAssertTrue(f.matches(tags: ["lame":"no"]))
        XCTAssertTrue(f.matches(tags: ["good":"yes"]))
        XCTAssertTrue(f.matches(tags: ["neme":"no"]))
        XCTAssertTrue(f.matches(tags: ["names":"yess"]))
        XCTAssertTrue(f.matches(tags: [:]))
    }
    
    func testMatchExactValueWithPipes() throws {
        let f = NotHasTagLike(key: "shop", value: "cheese|greengrocer")
        XCTAssertFalse(f.matches(tags: ["shop":"cheese"]))
        XCTAssertFalse(f.matches(tags: ["shop":"greengrocer"]))
        XCTAssertTrue(f.matches(tags: ["shop":"cheese_frog_swamp"]))
        XCTAssertTrue(f.matches(tags: ["shop":"cheese|greengrocer"]))
    }
    
    func testDescription() {
        XCTAssertEqual("~.ame !~ y.s", NotHasTagLike(key: ".ame", value: "y.s").description)
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
