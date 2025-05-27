//
//  UndoMerge.swift
//  GoInfoGameTests
//
//  Created by Prashamsa on 08/05/25.
//

import XCTest
@testable import GoInfoGame

final class UndoMerge: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testUndoMerge1() {
        // payload tags initial
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        // tag modified in the operation
        let edited: [String: String] = ["d":"1"]
        
        // Tags received from server for the element
        let serverTags: [String: String] = ["a": "1",
                                            "b": "2"]
        
        let expectedTagsAfterMerge: [String: String] = ["a": "1",
                                                        "b": "2"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTagsAfterMerge)
    }
    
    func testUndoMerge2() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["d":"1"]
        
        let serverTags: [String: String] = ["a": "2",
                                            "b": "2",
                                            "c": "3"]
        
        let expectedTags: [String: String] = ["a": "2",
                                              "b": "2",
                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge3() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["d":"1"]
        
        let serverTags: [String: String] = ["a": "2",
                                            "b": "2",
                                            "c": "3",
                                            "d" :"2"]
        
        let expectedTags: [String: String]? = nil
        //        ["a": "2",
        //                                              "b": "2",
        //                                              "c": "3",
        //                                              "d" :"2"]
        //
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge4() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["d":"1"]
        
        let serverTags: [String: String] = ["a": "1",
                                            "b": "2",
                                            "c": "3",
                                            "d" :"1"]
        
        let expectedTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge5() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["d":"1"]
        
        let serverTags: [String: String] = ["b": "2",
                                            "c": "3"]
        
        let expectedTags: [String: String] = ["b": "2",
                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge6() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["d":"1"]
        
        let serverTags: [String: String] = ["b": "3",
                                            "c": "3"]
        
        let expectedTags: [String: String] = ["b": "3",
                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge7() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["d":"1"]
        
        let serverTags: [String: String] = ["a": "1",
                                            "b": "2",
                                            "c": "3",
                                            "d" :"1",
                                            "e" : "1"]
        
        let expectedTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3",
                                              "e" : "1"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    // Edit cases
    
    func testUndoMerge8() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["a":"2"]
        
        let serverTags: [String: String] = ["a": "2",
                                            "b": "2"]
        
        let expectedTags: [String: String] = ["a": "1",
                                              "b": "2"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge9() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["a":"2"]
        
        let serverTags: [String: String] = ["a": "3",
                                            "b": "2",
                                            "c": "3"]
        
        let expectedTags: [String: String]? = nil
        //        ["a": "3",
        //                                              "b": "2",
        //                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge10() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["a":"2"]
        
        let serverTags: [String: String] = ["a": "2",
                                            "b": "2",
                                            "c": "3",
                                            "d" : "4"]
        
        let expectedTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3",
                                              "d" : "4"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge11() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["a":"2"]
        
        let serverTags: [String: String] = ["a": "1",
                                            "b": "2",
                                            "c": "3"]
        
        let expectedTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge12() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["a":"2"]
        
        let serverTags: [String: String] = ["b": "2",
                                            "c": "3"]
        
        let expectedTags: [String: String]? = nil
        //        ["b": "2",
        //                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func testUndoMerge13() {
        let originalTags: [String: String] = ["a": "1",
                                              "b": "2",
                                              "c": "3"]
        
        let edited: [String: String] = ["a":"2"]
        
        let serverTags: [String: String] = ["b": "3",
                                            "c": "3"]
        
        let expectedTags: [String: String]? = nil
        //        ["b": "3",
        //                                              "c": "3"]
        
        let resultTags = mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
        XCTAssertEqual(resultTags, expectedTags)
    }
    
    func mergeTagsForUndo(originalTags: [String : String], edited: [String : String], serverTags: [String : String]) -> [String : String]? {
        return DatasyncManager.shared.mergeTagsForUndo(originalTags: originalTags, edited: edited, serverTags: serverTags)
    }
}
