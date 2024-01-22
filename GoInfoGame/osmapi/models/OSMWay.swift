//
//  OSMWay.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
//import Foundation

// MARK: - OSMWayResponse
struct OSMWayResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let elements: [OSMWay]
}

// MARK: - Element
struct OSMWay: Codable {
    let type: String
    let id: Int
    let timestamp: Date
    let version, changeset: Int
    let user: String
    let uid: Int
    let nodes: [Int]
    let tags: [String:String]
}
