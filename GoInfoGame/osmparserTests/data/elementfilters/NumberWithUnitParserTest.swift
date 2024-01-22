//
//  NumberWithUnitParserTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/4/24.
//

import XCTest

@testable import osmparser

final class NumberWithUnitParserTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    private func parse(string:String) -> Double? {
        return string.withOptionalUnitToDoubleOrNull()
    }
    
    func testEmpty() throws {
        XCTAssertNil(parse(string: ""))
    }
    
    func testNumber() throws {
        XCTAssertEqual(1.0, parse(string: "1.0"))
        XCTAssertEqual(1.0, parse(string: "1"))
        XCTAssertEqual(1.0, parse(string: "1.00"))
        XCTAssertEqual(0.1, parse(string: "0.1"))
        XCTAssertEqual(0.1, parse(string: ".1"))
    }
    
    func testFeetAndInches() throws {
        let ft5in8 = 5 * 0.3048 + 8 * 0.0254
        XCTAssertEqual(ft5in8, parse(string: "5'8\""))
        XCTAssertEqual(ft5in8, parse(string: "5' 8\""))
        XCTAssertEqual(ft5in8, parse(string: "5 ' 8 \""))
        XCTAssertEqual(ft5in8, parse(string: "5 ft 8 in"))
        XCTAssertEqual(ft5in8, parse(string: "5ft8in"))
    }
    
    func testStandardUnits() throws {
        XCTAssertEqual(1.0, parse(string: "1m"))
        XCTAssertEqual(1.0, parse(string: "1 m"))
        XCTAssertEqual(1.0, parse(string: "1 km/h"))
        XCTAssertEqual(1.0, parse(string: "1 kph"))
        XCTAssertEqual(1.0, parse(string: "1 t"))
    }
    
    func testFeet() throws {
        let ft = 0.3048
        XCTAssertEqual(ft, parse(string: "1 ft"))
        XCTAssertEqual(ft, parse(string: "1 '"))
    }
    
    func testInches() throws {
        let inch = 0.0254
        XCTAssertEqual(inch, parse(string: "1 in"))
        XCTAssertEqual(inch, parse(string: "1 \""))
    }
    
    func testYards() throws {
        let yard = 0.9144
        XCTAssertEqual(yard, parse(string: "1 yd"))
        XCTAssertEqual(yard, parse(string: "1 yds"))
    }
    
    func testPounds() throws {
        let lb = 0.00045359237
        XCTAssertEqual(lb, parse(string: "1 lb"))
        XCTAssertEqual(lb, parse(string: "1 lbs"))
    }
    
    func testOthers() throws {
        XCTAssertEqual(0.001, parse(string: "1 mm"))
        XCTAssertEqual(0.01, parse(string: "1 cm"))
        XCTAssertEqual(1000.0, parse(string: "1 km"))
        XCTAssertEqual(0.001, parse(string: "1 kg"))
        XCTAssertEqual(1.609344, parse(string: "1 mph"))
        XCTAssertEqual(0.90718474, parse(string: "1 st"))
        XCTAssertEqual(1.0160469, parse(string: "1 lt"))
        XCTAssertEqual(0.05080234544, parse(string: "1 cwt"))
        
    }
    
    func testUnknownUnits() throws {
        XCTAssertNil(parse(string: "1 bananas"))
        XCTAssertNil(parse(string: "1 bananas 3 feet"))
        XCTAssertNil(parse(string: "speed 1 mph"))
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
