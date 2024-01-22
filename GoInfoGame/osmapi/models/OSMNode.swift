//
//  OSMNode.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
// Representation of a single node
// MARK: - OSMNodeResponse
struct OSMNodeResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let elements: [OSMNode]
}

// MARK: - Element
struct OSMNode: Codable {
    let type: String
    let id: Int
    let lat, lon: Double
    let timestamp: Date
    let version, changeset: Int
    let user: String
    let uid: Int
    let tags: [String:String]
}
