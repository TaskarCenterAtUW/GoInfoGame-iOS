//
//  QuestUndoManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 03/05/25.
//

import osmparser
import RealmSwift


class MapUndoManager {
    static let shared = MapUndoManager()
    
    private let realm: Realm
    
    var isUndoInProgress: Bool = false

    private init() {
        realm = try! Realm()
    }

    var updateTagsHandler: ((_ id: Int64, _ tags: [String: String], _ type: ElementType) -> Void)?

    func undo(for id: Int64, type: ElementType) {
        MapUndoManager.shared.isUndoInProgress = true
        switch type {
        case .way:
            guard let original = DatabaseConnector.shared.getWay(id: Int(id), version: .original),
                  let edited = DatabaseConnector.shared.getWay(id: Int(id), version: .edited) else {
                print("❌ Undo failed: Way not found")
                return
            }

            try? realm.write {
                edited.tags.removeAll()
                original.tags.forEach { edited.tags[$0.key] = $0.value }

                edited.polyline.removeAll()
                edited.polyline.append(objectsIn: original.polyline)

                edited.nodes.removeAll()
                edited.nodes.append(objectsIn: original.nodes)
            }

            updateTagsHandler?(id, edited.tags.toDictionary(), .way)

            try? realm.write {
                realm.delete(edited)
            }

        case .node:
            guard let original = DatabaseConnector.shared.getNode(id: Int(id), version: .original),
                  let edited = DatabaseConnector.shared.getNode(id: Int(id), version: .edited) else {
                print("❌ Undo failed: Node not found")
                return
            }

            try? realm.write {
                edited.tags.removeAll()
                original.tags.forEach { edited.tags[$0.key] = $0.value }
                edited.point = original.point
            }

            updateTagsHandler?(id, edited.tags.toDictionary(), .node)

        default:
            print("Unknown element type")
        }
    }


    
    func getUndoItems() -> [UndoItem] {
        let excludedKeys: Set<String> = ["ext:gig_complete", "ext:gig_last_updated"]
        var items: [UndoItem] = []

        let editedNodes = realm.objects(StoredNode.self)
        for edited in editedNodes {
            guard let original = DatabaseConnector.shared.getNode(id: edited.id, version: .original) else {
                print("⚠️ Original node not found for id: \(edited.id)")
                continue
            }

            let changedKeys = Set(edited.tags.keys)
                .union(original.tags.keys)
                .filter { key in
                    edited.tags[key] != original.tags[key] && !excludedKeys.contains(key)
                }

            if !changedKeys.isEmpty {
                items.append(UndoItem(elementId: edited.id, type: .node, changedKeys: Array(changedKeys)))
            }
        }

        let editedWays = realm.objects(StoredWay.self)
        for edited in editedWays {
            guard let original = DatabaseConnector.shared.getWay(id: edited.id, version: .original) else {
                print("⚠️ Original way not found for id: \(edited.id)")
                continue
            }

            let changedKeys = Set(edited.tags.keys)
                .union(original.tags.keys)
                .filter { key in
                    edited.tags[key] != original.tags[key] && !excludedKeys.contains(key)
                }

            if !changedKeys.isEmpty {
                items.append(UndoItem(elementId: edited.id, type: .way, changedKeys: Array(changedKeys)))
            }
        }

        return items
    }




}

extension MapUndoManager {
    func finalizeSuccessfulSubmit(id: Int, type: ElementType) {
        let realm = try! Realm()

        try? realm.write {
            switch type {
            case .way:
                if let original = DatabaseConnector.shared.getWay(id: id, version: .original) {
                    original.tags["ext:gig_complete"] = "yes"
                }
                if let edited = DatabaseConnector.shared.getWay(id: id, version: .edited) {
                    realm.delete(edited)
                }

            case .node:
                if let original = DatabaseConnector.shared.getNode(id: id, version: .original) {
                    original.tags["ext:gig_complete"] = "yes"
                }
                if let edited = DatabaseConnector.shared.getNode(id: id, version: .edited) {
                    realm.delete(edited)
                }

            default:
                break
            }

            if let changeset = DatabaseConnector.shared.getChangeset(for: Int64(id), type: type) {
                realm.delete(changeset)
            }
        }
    }


}


extension Map where Key == String, Value == String {
    func toDictionary() -> [String: String] {
        var dict: [String: String] = [:]
        forEach { entry in
            dict[entry.key] = entry.value
        }
        return dict
    }
}

extension StoredElementEnum {
    func toElementType() -> ElementType? {
        switch self {
        case .node: return .node
        case .way: return .way
        default: return nil
        }
    }
}
