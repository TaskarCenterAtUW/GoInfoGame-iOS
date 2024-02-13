//
//  OSMMapData.swift
//  osmapi
//
//  Created by Lakshmi Shweta Pochiraju on 13/02/24.
//

import Foundation

// MARK: - OSMMapData
struct OSMMapData: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let bounds: Bounds
    let elements: [Element]
}

// MARK: - Bounds
struct Bounds: Codable {
    let minlat, minlon, maxlat, maxlon: Double
}

// MARK: - Element
struct Element: Codable {
    let type: TypeEnum
    let id: Int
    let lat, lon: Double?
    let timestamp: Date
    let version, changeset: Int
    let user: String
    let uid: Int
    let tags: [String: String]?
    let nodes: [Int]?
    let members: [Member]?
}

// MARK: - Member
struct Member: Codable {
    let type: TypeEnum
    let ref: Int
    let role: Role
}

enum Role: String, Codable {
    case backward = "backward"
    case empty = ""
    case entrance = "entrance"
    case forward = "forward"
    case from = "from"
    case inner = "inner"
    case outer = "outer"
    case platform = "platform"
    case platformEntryOnly = "platform_entry_only"
    case platformExitOnly = "platform_exit_only"
    case route = "route"
    case stop = "stop"
    case stopEntryOnly = "stop_entry_only"
    case stopExitOnly = "stop_exit_only"
    case subwayEntrance = "subway_entrance"
    case to = "to"
    case via = "via"
}

enum TypeEnum: String, Codable {
    case node = "node"
    case relation = "relation"
    case way = "way"
}

