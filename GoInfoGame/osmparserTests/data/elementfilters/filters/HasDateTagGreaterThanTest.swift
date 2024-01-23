//
//  HasDateTagGreaterThanTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/5/24.
//

import XCTest

@testable import osmparser

final class HasDateTagGreaterThanTest: XCTestCase {
    
    let calendar = Calendar(identifier: .gregorian)
    let dateComponents = DateComponents(year: 2000 ,month: 11,day: 11)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testMatches() {
        let date =  calendar.date(from: dateComponents)!
        let c = HasDateTagGreaterThan(key: "check_date", dateFilter: FixedDate(theDate: date))
        XCTAssertFalse(c.matches(tags: [:]))
        XCTAssertFalse(c.matches(tags: ["check_date":"bla"]))
        XCTAssertTrue(c.matches(tags: ["check_date":"2000-11-12"]))
        XCTAssertFalse(c.matches(tags: ["check_date":"2000-11-11"]))
        XCTAssertFalse(c.matches(tags: ["check_date":"2000-11-10"]))
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
