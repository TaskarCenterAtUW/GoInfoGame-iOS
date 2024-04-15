//
//  StoredWay.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/23/24.
//

import Foundation

import RealmSwift
import osmparser
import MapKit
import osmapi

// Represents one stored way
class StoredWay: Object {
    
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var tags = Map<String,String>()
    @Persisted var version: Int = 0
    @Persisted var timestamp : String = ""
    @Persisted var nodes: List<Int64> = List<Int64>()
    // Need to persist the points
    @Persisted var polyline: List<CLLocationCoordinate2D> = List<CLLocationCoordinate2D>()
    
    
    public func asWay() -> Way {
        var theTags: [String:String] = [:]
        for (key,value) in tags.asKeyValueSequence(){
            theTags[key] = value
        }
        let nodeList:[Int64] = nodes.map({$0})
        let way = Way(id: Int64(id), version: version, tags: theTags, timestampEdited: 0, type: .way, nodeIds: nodeList)
        
        var latLong: [LatLon] = []
        for coordinate in polyline {
            let eachLatLong = LatLon(latitude: coordinate.latitude, longitude: coordinate.longitude)
            latLong.append(eachLatLong)
        }
        
        way.polyline = latLong
        return way
    }
    
    public func asOSMWay() -> OSMWay {
        var storage = [String: String]()
        for tag in tags {
            storage[tag.key] = tag.value
        }
        let nodes = Array(nodes.map { Int($0) })
        return OSMWay(type: "way", id: id, timestamp: Date(), version: version, changeset: -1, user: "", uid: -1, nodes: nodes, tags: storage)
    }
}
