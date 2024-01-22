//
//  OSMChangesetTests.swift
//  osmapiTests
//
//  Created by Naresh Devalapally on 1/21/24.
//

import XCTest
import Foundation
@testable import osmapi

final class OSMChangesetTests: XCTestCase {

    let testData = """
{
    "version": "0.6",
    "generator": "OpenStreetMap server",
    "copyright": "OpenStreetMap and contributors",
    "attribution": "http://www.openstreetmap.org/copyright",
    "license": "http://opendatacommons.org/licenses/odbl/1-0/",
    "changesets": [
        {
            "id": 146513063,
            "created_at": "2024-01-21T13:33:09Z",
            "open": true,
            "comments_count": 0,
            "changes_count": 1,
            "min_lat": 51.1184087,
            "min_lon": 7.4001298,
            "max_lat": 51.1184087,
            "max_lon": 7.4001298,
            "uid": 12999340,
            "user": "Otter Trey",
            "tags": {
                "comment": "Specify whether kerbs have tactile paving",
                "created_by": "StreetComplete 56.0",
                "locale": "de",
                "source": "survey",
                "StreetComplete:quest_type": "AddTactilePavingKerb"
            }
        },
        {
            "id": 146513062,
            "created_at": "2024-01-21T13:33:07Z",
            "open": false,
            "comments_count": 0,
            "changes_count": 3540,
            "closed_at": "2024-01-21T13:33:08Z",
            "min_lat": 33.5142022,
            "min_lon": 97.1160871,
            "max_lat": 33.8686597,
            "max_lon": 97.2435174,
            "uid": 9633527,
            "user": "Lepticed",
            "tags": {
                "comment": "Added buildings, roads, booth, waterway in China.",
                "created_by": "JOSM/1.5 (18940 fr)",
                "source": "Bing"
            }
        },
        {
            "id": 146513061,
            "created_at": "2024-01-21T13:33:07Z",
            "open": true,
            "comments_count": 0,
            "changes_count": 1,
            "min_lat": 51.1184087,
            "min_lon": 7.4001298,
            "max_lat": 51.1184087,
            "max_lon": 7.4001298,
            "uid": 12999340,
            "user": "Otter Trey",
            "tags": {
                "comment": "Determine the heights of kerbs",
                "created_by": "StreetComplete 56.0",
                "locale": "de",
                "source": "survey",
                "StreetComplete:quest_type": "AddKerbHeight"
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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        if let jsonData = testData.data(using: .utf8) {
            do {
                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .iso8601
                // Use JSONDecoder to decode the data into your struct or class
                let decodedObject = try jsonDecoder.decode(OSMChangesetResponse.self, from: jsonData)
                print(decodedObject)
                // Assert that there are some objects here
                XCTAssertEqual(decodedObject.changesets.count, 3)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        } else {
            print("Failed to convert JSON string to data.")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
