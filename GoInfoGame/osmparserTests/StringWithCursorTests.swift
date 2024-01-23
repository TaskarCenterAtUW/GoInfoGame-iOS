//
//  StringWithCursorTests.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 12/30/23.
//

import XCTest
@testable import osmparser


final class StringWithCursorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let strParser = StringWithCursor(stringValue:"abcded")
        let startPos = "abcded".startIndex
        let firstPos = "abcde".index(after: startPos)
        
        XCTAssertEqual(startPos, strParser.cursorIndex, "Start Position")
        XCTAssertEqual("a", strParser.advance(), "Advance")
        XCTAssertEqual(firstPos, strParser.cursorIndex, "Position after advance")
    }
    
    func testAdvance() throws {
        let strParser = StringWithCursor(stringValue:"abcded")
        let startPos = "abcded".startIndex
        let firstPos = "abcde".index(after: startPos)
        
        XCTAssertEqual(startPos, strParser.cursorIndex, "Start Position")
        XCTAssertEqual("a", strParser.advance(), "Advance")
        XCTAssertEqual(firstPos, strParser.cursorIndex, "Position after advance")
        
    }
    func testAdvanceBy() throws {
        let theString = "wundertuete"
        let startPos = theString.startIndex
        let x = StringWithCursor(stringValue: theString)
        XCTAssertEqual("wunder", x.advanceBy(x: 6))
        let cPosition = "wundertuete".index(startPos, offsetBy: 6)
        XCTAssertEqual(cPosition, x.cursorIndex)
        XCTAssertEqual("", x.advanceBy(x: 0))
        XCTAssertEqual(cPosition, x.cursorIndex)
        //TODO: fail when advance value < 0
        XCTAssertEqual("tuete", x.advanceBy(x: 9999))
        XCTAssertEqual(theString.endIndex, x.cursorIndex)
        XCTAssertTrue(x.isAtEnd())
        
    }
    
    func testRetreatBy() throws {
        let theString = "wundertuete"
        let x = StringWithCursor(stringValue: theString)
        x.advanceBy(x: 6)
        x.retreatBy(x: 999)
        XCTAssertEqual("wunder", x.advanceBy(x: 6))
        x.retreatBy(x: 3)
        XCTAssertEqual("dertue", x.advanceBy(x: 6))
    }
    
    func testNextIsAndAdvance() throws {
        let theString = "test123"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertTrue(x.nextIsAndAdvance(str: "te"))
        let cPosition = theString.index(theString.startIndex, offsetBy: 2)
        XCTAssertEqual(cPosition, x.cursorIndex)
        XCTAssertFalse(x.nextIsAndAdvance(str: "te"))
        x.advanceBy(x: 3)
        XCTAssertTrue(x.nextIsAndAdvance(str: "23"))
        let p = theString.index(theString.startIndex, offsetBy: 7)
        XCTAssertEqual(p, x.cursorIndex)
        XCTAssertTrue(x.isAtEnd())
    }
    
    func testNextIsAndAdvanceChar() {
        let theString = "test123"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertTrue(x.nextIsAndAdvance(c: "t"))
        XCTAssertEqual(theString.index(after: theString.startIndex), x.cursorIndex)
        XCTAssertFalse(x.nextIsAndAdvance(c: "t"))
        x.advanceBy(x: 3)
        XCTAssertTrue(x.nextIsAndAdvance(c: "1"))
        XCTAssertEqual(theString.index(theString.startIndex, offsetBy: 5), x.cursorIndex)
    }
    
    func testFindNext() {
        let theString = "abc abc"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertEqual("abc abc".count, x.findNext(str: "wurst"))
        XCTAssertEqual(0, x.findNext(str: "abc"))
        x.advance()
        XCTAssertEqual(3, x.findNext(str: "abc"))
        x.retreatBy(x: 999)
        XCTAssertEqual(4, x.findNext(str: "abc",offset: 1))
    }
    func testFindNextC(){
        let theString = "abc abc"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertEqual("abc abc".count, x.findNext(c: "x"))
        XCTAssertEqual(0, x.findNext(c: "a"))
        x.advance()
        XCTAssertEqual(3, x.findNext(c: "a"))
        x.advanceBy(x: 3)
        XCTAssertEqual(0, x.findNext(c: "a"))
    }
    
    func testFindNextRegex() {
        let theString = "abc abc"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertEqual(theString.count, x.findNext(regex: "x"))
        XCTAssertEqual(0, x.findNext(regex: "[a-z]{3}"))
        x.advance()
        XCTAssertEqual(3, x.findNext(regex: "[a-z]{3}")) // Not working. Need to fit it
    }
    
    func testFindNextMatchesString() {
        let theString = "abc123"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertNotNil(x.nextMatches(regex: "abc[0-9]"))
        XCTAssertNotNil(x.nextMatches(regex: "abc[0-9]{3}"))
        XCTAssertNil(x.nextMatches(regex: "abc[0-9]{4}"))
        x.advance()
        XCTAssertNotNil(x.nextMatches(regex: "bc[0-9]"))
    }
    
    func testMatchesStringAndAdvance() {
        let theString = "abc123"
        let x = StringWithCursor(stringValue: theString)
        XCTAssertNotNil(x.nextMatchesAndAdvance(regex: "abc[0-9]"))
        let theTargetIndex = theString.index(theString.startIndex, offsetBy: 4)
        XCTAssertEqual(theTargetIndex, x.cursorIndex)
        XCTAssertNil(x.nextMatchesAndAdvance(regex: "[a-z]"))
        XCTAssertNil(x.nextMatchesAndAdvance(regex: "[0-9]{3}"))
        XCTAssertNotNil(x.nextMatchesAndAdvance(regex: "[0-9]{2}"))
        XCTAssertTrue(x.isAtEnd())
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
