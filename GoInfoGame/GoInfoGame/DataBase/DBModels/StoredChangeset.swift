//
//  StoredChangeset.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/29/24.
//
// Defines the changes applied to a single node/way elements
import Foundation

import RealmSwift
import osmparser
import CoreLocation
import osmapi

enum StoredElementEnum: String, PersistableEnum {
    case node
    case way
    case unknown
    
    func elementType() -> ElementType {
        switch self {
        case .node:
            return .node
        case .way:
            return .way
        default:
            return .node
        }
    }
}

// Represents one stored way
class StoredChangeset: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString // Internal ID
    // Type of change -> can be node or way
    @Persisted var elementType : StoredElementEnum = .unknown
    @Persisted var elementId: Int // The ID of the element
    @Persisted var tags = Map<String,String>()
    @Persisted var originalTags = Map<String,String>()
    @Persisted var changesetId: Int = -1 // Initial value of changeset // To be figured out later as index
    @Persisted var timestamp : String = "" // User time stamp
    @Persisted var version: Int = 0
    @Persisted var point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @Persisted var nodes: List<Int64> = List<Int64>()
    @Persisted var updatedVersion: Int = -1
    
    public func asOSMWay(isUndo: Bool = false) -> OSMWay {
        var storage = originalTags.toDictionary()
        if !isUndo {
            for tag in tags {
                storage[tag.key] = tag.value
            }
        }
        let nodes = Array(nodes.map { Int($0) })
        return OSMWay(type: "way",
                      id: elementId,
                      timestamp: Date(),
                      version: isUndo ? updatedVersion : version,
                      changeset: -1,
                      user: "",
                      uid: -1,
                      nodes: nodes,
                      tags: storage)
    }
    
    public func asOSMNode(isUndo: Bool = false) -> OSMNode {
        var storage = originalTags.toDictionary()
        if !isUndo {
            for tag in tags {
                storage[tag.key] = tag.value
            }
        }
        return OSMNode(type: "node",
                       id: elementId,
                       lat: point.latitude,
                       lon: point.longitude,
                       timestamp: Date(),
                       version: isUndo ? updatedVersion : version,
                       changeset: -1,
                       user: "",
                       uid: -1,
                       tags: storage)
    }
}
