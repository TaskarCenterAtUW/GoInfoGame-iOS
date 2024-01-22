//
//  BooleanExpressionBuilderTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/2/24.
//

import XCTest

@testable import osmparser

final class BooleanExpressionBuilderTest: XCTestCase {

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
    
    func testAllSmalls() throws {
        check(input: "a") // Leaf
        check(input: "a*b") // and
        check(input: "a+b") // or
        check(input: "a*b*c") // and3
        check(input: "a+b+c") // or3
        check(input: "a*b+c") //andor
        check(input: "a+b*c") //orAnd
        check(input: "a+b*c+d") // andInOr
        check(input: "a*b+c*d") // andInOr2
        check(input: "(a)",expected: "a") // brackets0
        check(input: "(a*b)", expected: "a*b")
        check(input: "(a+b)", expected: "a+b")
        check(input: "((a*b))",expected: "a*b")
        check(input: "((a+b))",expected: "a+b")
        check(input: "(a+b)*c")
        check(input: "a*(b+c)")
        check(input: "a*(b+c)*d")
        
        check(input: "(a*b)+c", expected: "a*b+c")
        
        check(input: "a+(b*c)", expected: "a+b*c")
        check(input: "a*(b*c)", expected: "a*b*c")
        check(input: "(a*b)*c", expected: "a*b*c")
        check(input: "(a+b)+c", expected: "a+b+c")
        check(input: "a+(b+c)", expected: "a+b+c")
        check(input: "(a*b+c)", expected: "a*b+c")
        check(input: "(a+b*c)", expected: "a+b*c")
        check(input: "(((a+b*c)))", expected: "a+b*c")
    }
    
    func testMerges() {
        check(input: "a+(b+(c+(d)))", expected: "a+b+c+d") // merge1
        check(input: "a*(b*(c*(d)))", expected: "a*b*c*d") // merge2
        check(input: "a*(b+(c*(d)))", expected: "a*(b+c*d)") // merge3
        check(input: "a+(b*(c+(d)))", expected: "a+b*(c+d)") // merge4
        
        check(input: "(((a)+b)+c)+d", expected: "a+b+c+d") // merge5
        check(input: "(((a)*b)*c)*d", expected: "a*b*c*d") // merge6
        check(input: "(((a)+b)*c)+d", expected: "(a+b)*c+d") // merge7
        check(input: "(((a)*b)+c)*d", expected: "(a*b+c)*d") // merge8
        check(input: "(a+b*c)*d", expected: "(a+b*c)*d") // merge9
        check(input: "(a+b*c)*d*(e+f*g)*h", expected: "(a+b*c)*d*(e+f*g)*h") // merge10
        
    }
    
    func testFlatten() {
        check(input: "((a*b)*c)*d*(e*f)", expected: "a*b*c*d*e*f")
        check(input: "(a+b*(c+d)+e)*f", expected: "(a+b*(c+d)+e)*f")
    }
    
    func testTooManyBrackets1(){
        XCTAssertThrowsError(try TestBooleanExpressionParser.shared.parse(input: "a+b)")){error in
            XCTAssertTrue(error is IllegalStateException)
        }
    }
    
    func testTooManyBrackets2() {
        XCTAssertThrowsError(try TestBooleanExpressionParser.shared.parse(input: "(a+b))")){error in
            XCTAssertTrue(error is IllegalStateException)
        }
    }
    
    func testTooManyBrackets3() {
        XCTAssertThrowsError(try TestBooleanExpressionParser.shared.parse(input: "((b+c)*a)+d)")){error in
            XCTAssertTrue(error is IllegalStateException)
        }
    }
    
    func testFewBrackets1(){
        XCTAssertThrowsError(try TestBooleanExpressionParser.shared.parse(input: "(a+b")){error in
            XCTAssertTrue(error is IllegalStateException)
        }
    }
    
    func testFewBrackets2(){
        XCTAssertThrowsError(try TestBooleanExpressionParser.shared.parse(input: "((a+b)")){error in
            XCTAssertTrue(error is IllegalStateException)
        }
    }
    
    func testFewBrackets3(){
        XCTAssertThrowsError(try TestBooleanExpressionParser.shared.parse(input: "((a*(b+c))")){error in
            XCTAssertTrue(error is IllegalStateException)
        }
    }
    
    func testOrAnd() throws {
        
    }
    
    private func check(input: String, expected:String ) {
        let tree = try? TestBooleanExpressionParser.shared.parse(input: input)
        let treeDesc = translateOutput(output: tree!.description)
        XCTAssertEqual(expected,treeDesc)
    }
    
    private func check(input:String) {
        check(input: input,expected: input)
    }
    
    private func translateOutput(output:String) -> String {
        return output.replacingOccurrences(of: " and ", with: "*").replacingOccurrences(of: " or ", with: "+")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
