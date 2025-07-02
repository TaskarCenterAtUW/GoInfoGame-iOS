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
import osmapi

// Stores a node instance
class StoredNode : Object {
    
    @Persisted(primaryKey: true) var id: Int64
    @Persisted var tags = Map<String,String>()
    @Persisted var version: Int = 0
    @Persisted var timestamp : Date
    @Persisted var point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        
    // Give another method that gives node
    public func asNode() -> Node {
        let position = LatLon(latitude: point.latitude , longitude: point.longitude)
        var theTags: [String:String] = [:]
        for (key,value) in tags{
            theTags[key] = value
        }
        let n = Node(id: id, version: version, tags: theTags, timestampEdited: 0, position: position)
        return n
    }
}
