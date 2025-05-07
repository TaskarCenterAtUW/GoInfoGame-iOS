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

    private init() {
        realm = try! Realm()
    }

    var updateTagsHandler: ((_ id: Int64, _ tags: [String: String], _ type: ElementType) -> Void)?

    func undo(for id: Int64, type: ElementType) {
        switch type {
        case .way:
            guard let original = DatabaseConnector.shared.getWay(id: Int(id), version: .original),
                  let current = DatabaseConnector.shared.getWay(id: Int(id), version: .edited) else {
                print("Undo failed: Way not found")
                return
            }

            try? realm.write {
                current.tags.removeAll()
                original.tags.forEach { current.tags[$0.key] = $0.value }

                current.polyline.removeAll()
                current.polyline.append(objectsIn: original.polyline)

                current.nodes.removeAll()
                current.nodes.append(objectsIn: original.nodes)

//                current.version += 1
            }

            updateTagsHandler?(id, current.tags.toDictionary(), .way)
            
            if let changeset = DatabaseConnector.shared.getChangeset(for: id, type: type) {
                try? realm.write {
                    realm.delete(changeset)
                }
            }
            
            if let edited = DatabaseConnector.shared.getWay(id: Int(id), version: .edited) {
                try? realm.write {
                    realm.delete(edited)
                }
            }

        case .node:
            guard let original = DatabaseConnector.shared.getNode(id: Int(id), version: .original),
                  let current = DatabaseConnector.shared.getNode(id: Int(id), version: .edited)else {
                print(" Undo failed: Node not found")
                return
            }

            try? realm.write {
                current.tags.removeAll()
                original.tags.forEach { current.tags[$0.key] = $0.value }

                current.point = original.point
             //   current.version += 1
            }

            updateTagsHandler?(id, current.tags.toDictionary(), .node)
            
            if let changeset = DatabaseConnector.shared.getChangeset(for: id, type: type) {
                try? realm.write {
                    realm.delete(changeset)
                }
            }
            
            if let edited = DatabaseConnector.shared.getNode(id: Int(id), version: .edited) {
                try? realm.write {
                    realm.delete(edited)
                }
            }

        default:
            print(" Unknown element type")
        }
    }
    
    func getUndoItems() -> [UndoItem] {
        let changesets = DatabaseConnector.shared.getChangesets(synced: true)

        var seen = Set<String>()
        
        return changesets.compactMap { cs in
            guard let type = cs.elementType.toElementType() else { return nil }
            let key = "\(cs.elementId)-\(type)"
            
            if seen.contains(key) {
                return nil // Skip duplicates
            } else {
                seen.insert(key)
                let changedKeys = cs.tags.map { $0.key }
                return UndoItem(elementId: Int(cs.elementId) ?? -1, type: type, changedKeys: changedKeys)
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
