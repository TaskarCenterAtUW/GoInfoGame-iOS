//
//  OSMXMLBuilderTests.swift
//  osmapiTests
//
//  Created by Naresh Devalapally on 1/22/24.
//

import XCTest

@testable import osmapi

final class OSMXMLBuilderTests: XCTestCase {

    let testString = """
<osm>
    <node changeset="188021" id="4977475294" lat="38.8983803" lon="-77.0465589" version="4">
        <tag k="barrier" v="kerb" />
        <tag k="kerb" v="lowered" />
        <tag k="tactile_paving" v="yes" />
    </node>
</osm>
"""
    let testNodeData = """
        {
            "type": "node",
            "id": 4977475294,
            "lat": 38.8983803,
            "lon": -77.0465589,
            "timestamp": "2023-04-09T20:10:24Z",
            "version": 4,
            "changeset": 134701569,
            "user": "Peter Newman",
            "uid": 7096975,
            "tags": {
                "barrier": "kerb",
                "kerb": "lowered",
                "tactile_paving": "yes"
            }
        }
"""
    var testNode : OSMNode? = nil
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if let jsonData = testNodeData.data(using: .utf8){
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601
            let decodedObject = try jsonDecoder.decode(OSMNode.self, from: jsonData)
            testNode = decodedObject
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSimpleBuilder() throws {
        let xmlBuilder = OSMXMLBuilder(rootName: "osm")
        xmlBuilder.addAttribute(name: "version", value: "1")
        xmlBuilder.addAttribute(name: "changeset", value: "188021")
        let builtString = xmlBuilder.buildXML()
        print(builtString)
        XCTAssertNotNil(builtString)
        let expectedString = "<osm version = \"1\",changeset = \"188021\" />"
        XCTAssertEqual(builtString, expectedString)
    }
    
    func testPayloadForNode() throws {
        XCTAssert(testNode != nil)
        // Start with the stuff.
        let xmlBuilder = OSMXMLBuilder(rootName: "osm")
        let xmlBuiltString = testNode?.toPayload()
        print(xmlBuiltString)
        XCTAssert(xmlBuiltString != nil)
        
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
