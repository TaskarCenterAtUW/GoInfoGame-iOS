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
    public var isInteresting: Bool? = false
    public var isSkippable: Bool? = false
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
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isInteresting = try values.decodeIfPresent(Bool.self, forKey: .isInteresting) ?? false
        isSkippable = try values.decodeIfPresent(Bool.self, forKey: .isSkippable) ?? false
        id = try values.decodeIfPresent(Int.self, forKey: .id) ?? 0
        lat = try values.decodeIfPresent(Double.self, forKey: .lat) ?? 0.0
        lon = try values.decodeIfPresent(Double.self, forKey: .lon) ?? 0.0
        timestamp = try values.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        version = try values.decodeIfPresent(Int.self, forKey: .version) ?? 0
        changeset = try values.decodeIfPresent(Int.self, forKey: .changeset) ?? 0
        user = try values.decodeIfPresent(String.self, forKey: .user) ?? ""
        uid = try values.decodeIfPresent(Int.self, forKey: .uid) ?? 0
        tags = try values.decodeIfPresent([String: String].self, forKey: .tags) ?? [:]
        nodes = try values.decodeIfPresent([Int].self, forKey: .nodes) ?? []
        type = try values.decodeIfPresent(TypeEnum.self, forKey: .type) ?? TypeEnum.node
        members = try values.decodeIfPresent([Member].self, forKey: .members) ?? []
    }
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

