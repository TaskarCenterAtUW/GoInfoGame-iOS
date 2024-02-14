//
//  OSMMapData.swift
//  osmapi
//
//  Created by Lakshmi Shweta Pochiraju on 13/02/24.
//

import Foundation

// MARK: - OSMMapData
public struct OSMMapDataResponse: Codable {
    public let version, generator, copyright: String
    public let attribution, license: String
    public let bounds: Bounds
    public let elements: [Element]
}

// MARK: - Bounds
public struct Bounds: Codable {
    public let minlat, minlon, maxlat, maxlon: Double
}

// MARK: - Element
public struct Element: Codable, OSMElement {
    public var isInteresting: Bool = false
    public var isSkippable: Bool = false
    public let type: TypeEnum
    public let id: Int
    public let lat, lon: Double?
    public let timestamp: Date
    public var version, changeset: Int
    public let user: String
    public let uid: Int
    public let tags: [String: String]
    public let nodes: [Int]?
    public let members: [Member]?
}

// MARK: - Member
public struct Member: Codable {
    public let type: TypeEnum
    public let ref: Int
    public let role: Role
}

public enum Role: String, Codable {
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

public enum TypeEnum: String, Codable {
    case node = "node"
    case relation = "relation"
    case way = "way"
}

