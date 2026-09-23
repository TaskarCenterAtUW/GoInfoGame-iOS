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
    @Persisted var isUndoCompleted: Bool = false
    @Persisted var undoOn: Date? = nil
    @Persisted var questType: String?
    @Persisted var iconName: String
    /// True for a changeset representing a brand-new element (Add Feature), rather
    /// than an edit to one that already existed. `QuestBase.updateUndoTags` checks
    /// this to delete the element on undo instead of restoring `originalTags`.
    @Persisted var isCreatedElement: Bool = false

    /// A captured-but-not-yet-uploaded KartaView photo tied to this answer, saved to
    /// disk by `QuestImageStorage`. Non-nil until `QuestSubmissionManager` uploads it
    /// and writes the resulting URL into `tags[pendingImageTagKey]`, clearing both.
    @Persisted var pendingImagePath: String?
    /// Which tag key the uploaded photo's URL should be written to (e.g.
    /// "ext:kartaview_url"). Only meaningful while `pendingImagePath` is non-nil.
    @Persisted var pendingImageTagKey: String?
    @Persisted var retryCount: Int = 0
    @Persisted var lastError: String?

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

/// Plain-value mirror of a StoredChangeset. Realm objects are confined to the thread/
/// Realm instance that fetched them, so this is what crosses into async Task and actor
/// contexts while a queued quest answer (and its optional pending photo) is retried.
/// `asOSMNode()`/`asOSMWay()` replicate `StoredChangeset`'s own originalTags+tags merge
/// logic, since `QuestSubmissionManager.attempt` mutates `tags` in-memory with an
/// uploaded photo URL before building the payload, without touching the Realm object.
struct StoredChangesetSnapshot {
    let id: String
    let elementId: Int
    let elementType: StoredElementEnum
    let questType: String
    let iconName: String
    let tags: [String: String]
    let originalTags: [String: String]
    let version: Int
    let point: CLLocationCoordinate2D
    let nodes: [Int64]
    let pendingImagePath: String?
    let pendingImageTagKey: String?

    func asOSMNode(tags overrideTags: [String: String]) -> OSMNode {
        var storage = originalTags
        for (key, value) in overrideTags { storage[key] = value }
        return OSMNode(type: "node", id: elementId, lat: point.latitude, lon: point.longitude,
                        timestamp: Date(), version: version, changeset: -1, user: "", uid: -1, tags: storage)
    }

    func asOSMWay(tags overrideTags: [String: String]) -> OSMWay {
        var storage = originalTags
        for (key, value) in overrideTags { storage[key] = value }
        return OSMWay(type: "way", id: elementId, timestamp: Date(), version: version, changeset: -1,
                       user: "", uid: -1, nodes: nodes.map { Int($0) }, tags: storage)
    }
}
