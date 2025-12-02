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
        realm = try! Realm(configuration: RealmConfig.configuration)
    }

    var updateTagsHandler: ((_ changeset: StoredChangeset?) -> Void)?

    func undo(for id: String) {
        guard let changeSet = DatabaseConnector.shared.getChangeset(for: id) else {
            print("❌ Undo failed: Element not found")
            updateTagsHandler?(nil)
            return
        }

        updateTagsHandler?(changeSet)
    }

    
    func getUndoItems() -> [UndoItem] {
        var items: [UndoItem] = []

        let editedNodes = realm.objects(StoredChangeset.self).filter("changesetId == 0 && isUndoCompleted == false")
        for edited in editedNodes {
            let keys = Array(edited.tags.keys)
            if !keys.isEmpty {
                let date = Date(timeIntervalSince1970: Double(edited.timestamp) ?? 0.0)
                var tagActions: [(action: UndoItem.TagAction, key: String, value: String)] = []
                for key in keys {
                    if let value = edited.originalTags[key] {
                        tagActions.append((.modified, key, value))
                    } else {
                        tagActions.append((.added, key, edited.tags[key] ?? ""))
                    }
                }
                items.append(UndoItem(elementId: edited.elementId, type: edited.elementType.elementType(), changedKeys: keys, id: edited.id, timestamp: date, questType: edited.questType, tags: tagActions, iconName: edited.iconName))
            }
        }

        return items
    }
}

//FIXME: This is completely removed
extension MapUndoManager {
//    func finalizeSuccessfulSubmit(id: Int, type: ElementType) {
//        let realm = try! Realm()
//
//        try? realm.write {
//            switch type {
//            case .way:
//                if let original = DatabaseConnector.shared.getWay(id: id) {
//                    original.tags["ext:gig_complete"] = "yes"
//                }
//                if let edited = DatabaseConnector.shared.getWay(id: id) {
//                    realm.delete(edited)
//                }
//
//            case .node:
//                if let original = DatabaseConnector.shared.getNode(id: id) {
//                    original.tags["ext:gig_complete"] = "yes"
//                }
//                if let edited = DatabaseConnector.shared.getNode(id: id) {
//                    realm.delete(edited)
//                }
//
//            default:
//                break
//            }
//
//            if let changeset = DatabaseConnector.shared.getChangeset(for: Int64(id), type: type) {
//                realm.delete(changeset)
//            }
//        }
//    }


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
    //FIXME: this is shown twice
    func toElementType() -> ElementType? {
        switch self {
        case .node: return .node
        case .way: return .way
        default: return nil
        }
    }
}
