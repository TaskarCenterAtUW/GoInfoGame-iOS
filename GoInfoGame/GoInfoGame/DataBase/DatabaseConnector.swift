//
//  DatabaseConnector.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 25/11/23.
//

import Foundation
import RealmSwift
import SwiftOverpassAPI

class DatabaseConnector {
    static let shared = DatabaseConnector()
    
    private let realm: Realm
    
    private init() {
        // Initialize Realm instance
        realm = try! Realm()
        if let realmURL = realm.configuration.fileURL {
            print("Realm Database Path: \(realmURL.path)")
        }
    }
    
    func saveElements(_ elements: [OPWay]) {
        do {
            try realm.write {
                for element in elements {
                    let realmElement = RealmOPElement()
                    realmElement.id = element.id
                    realmElement.isInteresting = element.isInteresting
                    realmElement.isSkippable = element.isSkippable
                    
                    let realmTags = element.tags.map { tag in
                        let realmTag = RealmOPElementTag()
                        realmTag.key = tag.key
                        realmTag.value = tag.value
                        return realmTag
                    }
                    realmElement.tags.append(objectsIn: realmTags)
                    
                    if let meta = element.meta {
                        let realmMeta = RealmOPMeta()
                        realmMeta.version = meta.version
                        realmMeta.timestamp = meta.timestamp
                        realmMeta.changeset = meta.changeset
                        realmMeta.userId = meta.userId
                        realmMeta.username = meta.username
                        realmElement.meta = realmMeta
                    } else {
                        realmElement.meta = RealmOPMeta()
                    }
                    
                    if !element.nodes.isEmpty {
                        realmElement.nodes.append(objectsIn: element.nodes)
                    }
                    let geometry =  RealmOPGeometry(geometry: element.geometry)
                    realmElement.geometry.append(geometry)
                    realm.add(realmElement, update: .modified)
                }
            }
        } catch {
            print("Error saving elements to Realm: \(error)")
        }
    }
    
    func getElements() -> Results<RealmOPElement> {
        return realm.objects(RealmOPElement.self)
    }
    
    func deleteAllElements() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Error deleting all elements from Realm: \(error)")
        }
    }
    
    func getElementWith(_ id: Int) -> RealmOPElement? {
        return realm.object(ofType: RealmOPElement.self, forPrimaryKey: id)
    }
}
