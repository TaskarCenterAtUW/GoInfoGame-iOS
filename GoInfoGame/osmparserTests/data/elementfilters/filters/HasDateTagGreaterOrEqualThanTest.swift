//
//  HasDateTagGreaterOrEqualThanTest.swift
//  QParserTests
//
//  Created by Achyut Kumar M on 10/01/24.
//

import XCTest
@testable import osmparser

final class HasDateTagGreaterOrEqualThanTest: XCTestCase {
    
    let calendar = Calendar(identifier: .gregorian)
    let dateComponents = DateComponents(year: 2000 ,month: 11,day: 11)
    
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testMatches() throws {
        let date =  calendar.date(from: dateComponents)!
        let c = HasDateTagGreaterOrEqualThan(key: "check_date", dateFilter: FixedDate(theDate: date))
        
        XCTAssertFalse(c.matches(tags: [:]))
        XCTAssertFalse(c.matches(tags: ["check_date": "bla"]))
        XCTAssertTrue(c.matches(tags: ["check_date": "2000-11-12"]))
        XCTAssertTrue(c.matches(tags: ["check_date": "2000-11-11"]))
        XCTAssertFalse(c.matches(tags: ["check_date": "2000-11-10"]))
    }
    
    func testDescription() throws {
        let date =  calendar.date(from: dateComponents)!
        let c = HasDateTagGreaterOrEqualThan(key: "check_date", dateFilter: FixedDate(theDate: date))
        XCTAssertEqual("check_date >= \(date)", c.description)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
