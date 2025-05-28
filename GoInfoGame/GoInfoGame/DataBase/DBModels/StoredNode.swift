//
//  StoredNode.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/23/24.
//

import Foundation
import RealmSwift
import osmparser
import MapKit

// Stores a node instance
class StoredNode : Object {
    
    @Persisted(primaryKey: true) var compoundId: String
    @Persisted var id: Int
    @Persisted var tags = Map<String,String>()
    @Persisted var version: Int = 0
    @Persisted var timestamp : String = ""
    @Persisted var point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    @Persisted var isOriginal: Bool = false
    
    func generateCompoundId() {
        self.compoundId = "\(id)-\(isOriginal ? "original" : "edited")"
    }
    
    // Give another method that gives node
    func asNode() -> Node {
        let position = LatLon(latitude: point.latitude , longitude: point.longitude)
        var theTags: [String:String] = [:]
        for (key,value) in tags{
            theTags[key] = value
        }
        let n = Node(id: Int64(id), version: version, tags: theTags, timestampEdited: 0, position: position)
        return n
    }
}
