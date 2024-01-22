//
//  BooleanExpressionTests.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/2/24.
//

import XCTest
@testable import osmparser

final class BooleanExpressionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
    
    func testMatchLeaf() throws {
        XCTAssertTrue(evalExpression(input: "1"))
        XCTAssertFalse(evalExpression(input: "0"))
    }
    
    func testMatchOr() throws {
        XCTAssertTrue(evalExpression(input: "1+1"))
        XCTAssertTrue(evalExpression(input: "1+0"))
        XCTAssertTrue(evalExpression(input: "0+1"))
        XCTAssertTrue(evalExpression(input: "0+0+1"))
        XCTAssertFalse(evalExpression(input: "0+0"))
    }
    
    func testMatchAnd() throws {
        XCTAssertTrue(evalExpression(input: "1*1"))
        XCTAssertFalse(evalExpression(input: "1*0"))
        XCTAssertFalse(evalExpression(input: "0*1"))
        XCTAssertFalse(evalExpression(input: "0*0"))
        
        XCTAssertTrue(evalExpression(input: "1*1*1"))
        XCTAssertFalse(evalExpression(input: "1*1*0"))
        
    }
    
    func testMatchAndInOr() {
        XCTAssertTrue(evalExpression(input: "(1*0)+1"))
        XCTAssertFalse(evalExpression(input: "(1*0)+0"))
        XCTAssertTrue(evalExpression(input: "(1*1)+0"))
        XCTAssertTrue(evalExpression(input: "(1*1)+1"))
    }
    
    func testMatchOrInAnd() {
        
        XCTAssertTrue(evalExpression(input: "(1+0)*1"))
        XCTAssertFalse(evalExpression(input: "(1+0)*0"))
        XCTAssertFalse(evalExpression(input: "(0+0)*0"))
        XCTAssertFalse(evalExpression(input: "(0+0)*1"))
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    private func evalExpression(input: String) -> Bool{
        let expr = try! TestBooleanExpressionParser.shared.parse(input: input)
        return expr!.matches("1")
    }

}
