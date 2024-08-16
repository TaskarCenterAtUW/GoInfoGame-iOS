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
    
   public func getOSMElements() -> [Int:OSMElement]{
        var newMap :[Int: OSMElement] = [:]
        elements.forEach { ele in
            if let osmElement = ele.toOSMElement() {
                newMap[osmElement.id] = osmElement
            }
        }
        // Try to see if we can figure out way locations as well.
        return newMap
    }
}

// MARK: - Bounds
public struct Bounds: Codable { // use this for bounds in the map
    public let minlat, minlon, maxlat, maxlon: Double
}

// MARK: - Element
public struct Element: Codable {
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
    
    func toOSMElement() -> OSMElement? {
        switch type {
        case .node:
            return toOSMNode()
        case .way:
            return toOSMWay()
        case .relation:
            return nil
        }
    }
    
    internal func toOSMNode() -> OSMNode {
        OSMNode(type: "node", id: id, lat: lat!, lon: lon!, timestamp: timestamp, version: version, changeset: changeset, user: user, uid: uid,tags: tags)
    }
    internal func toOSMWay() -> OSMWay {
        OSMWay(type: "way", id: id, timestamp: timestamp, version: version, changeset: changeset, user: user, uid: uid, nodes: nodes ?? [], tags: tags)
    }
}

// MARK: - Member
public struct Member: Codable {
    public let type: TypeEnum
    public let ref: Int
    public let role: String
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

