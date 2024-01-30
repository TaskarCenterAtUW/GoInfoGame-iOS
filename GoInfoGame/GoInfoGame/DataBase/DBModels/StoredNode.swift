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
    
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var tags = Map<String,String>()
    @Persisted var version: Int = 0
    @Persisted var timestamp : String = ""
    @Persisted var point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    // Give another method that gives node
    public func asNode() -> Node {
        let position = LatLon(latitude: point.latitude , longitude: point.longitude)
        var theTags: [String:String] = [:]
        for (key,value) in tags.asKeyValueSequence(){
            theTags[key] = value
        }
        let n = Node(id: Int64(id), version: version, tags: theTags, timestampEdited: 0, position: position)
        return n
    }
    
    public func asOSMNode() -> OSMNode {
        return OSMNode(type: "node", id: id, lat: point.latitude, lon: point.longitude, timestamp: Date(), version: version, changeset: -1, user: "", uid: -1)
    }
}
