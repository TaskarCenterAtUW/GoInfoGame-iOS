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
                current.version += 1
            }

            updateTagsHandler?(id, current.tags.toDictionary(), .node)

        default:
            print(" Unknown element type")
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
