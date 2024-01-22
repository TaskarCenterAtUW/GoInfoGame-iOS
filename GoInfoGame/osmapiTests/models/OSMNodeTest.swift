//
//  OSMNodeTest.swift
//  osmapiTests
//
//  Created by Naresh Devalapally on 1/22/24.
//

import XCTest
import Foundation
@testable import osmapi

final class OSMNodeTest: XCTestCase {

    let testData = """
{
    "version": "0.6",
    "generator": "CGImap 0.8.10 (947166 spike-07.openstreetmap.org)",
    "copyright": "OpenStreetMap and contributors",
    "attribution": "http://www.openstreetmap.org/copyright",
    "license": "http://opendatacommons.org/licenses/odbl/1-0/",
    "elements": [
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
    ]
}
"""
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testModel() throws {
        if let jsonData = testData.data(using: .utf8) {
            do {
                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .iso8601
                // Use JSONDecoder to decode the data into your struct or class
                let decodedObject = try jsonDecoder.decode(OSMNodeResponse.self, from: jsonData)
                print(decodedObject)
                // Assert that there are some objects here
                XCTAssertEqual(decodedObject.elements.count, 1)
            } catch {
                print("Error decoding JSON: \(error)")
                XCTFail("Error decoding the JSON")
            }
        } else {
            XCTFail("Failed to convert JSON string to data.")
        }
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
