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
    
    func saveElements(_ elements: [OPElement]) {
        // Save the elements appropriately
        // Get the ways and nodes out
        let nodes = elements.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
        let ways = elements.filter({$0 is OPWay}).filter({!$0.tags.isEmpty})
        do {
            try realm.write {
                for node in nodes {
                    let storedElement = StoredNode()
                    storedElement.id = node.id
                    for tag in node.tags {
                        storedElement.tags.setValue(tag.value, forKey: tag.key)
                    }
                    if let meta = node.meta {
                        storedElement.version = meta.version
                        storedElement.timestamp = meta.timestamp
                    }
                    if let asNode = node as? OPNode{
                        switch asNode.geometry {
                        case .center(let coordinate):
                            storedElement.point = coordinate
                        default:
                            continue
                        }
                    }
                    realm.add(storedElement, update: .modified)
                }
                // Store the ways
                for way in ways {
                    let storedWay = StoredWay()
                    storedWay.id = way.id
                    for tag in way.tags {
                        storedWay.tags.setValue(tag.value, forKey: tag.key)
                    }
                    
                    if let meta = way.meta {
                        storedWay.version = meta.version
                        storedWay.timestamp = meta.timestamp
                    }
                    if let asWay = way as? OPWay {
                        storedWay.nodes.append(objectsIn: asWay.nodes.map({Int64($0)}))
                    }
                    realm.add(storedWay, update: .modified)
                }
            }
        } catch {
            print("Elements to be skipped or something happened")
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
    
    func getNodes() -> Results<StoredNode> {
        return realm.objects(StoredNode.self)
    }
    func getWays() -> Results<StoredWay> {
        return realm.objects(StoredWay.self)
    }
    
}
