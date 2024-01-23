//
//  StoredElement.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
import RealmSwift
import osmparser
// Base class for storing stuff. Not sure what @Persisted means
class StoredElement : Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var tags = Map<String,String>()
    @Persisted var version: Int = 0
    
    // Give another method that gives node
    public func asNode() -> Node {
        let position = LatLon(latitude: 0.0, longitude: 0.0)
        var theTags: [String:String] = [:]
        for (key,value) in tags.asKeyValueSequence(){
            theTags[key] = value
        }
        let n = Node(id: Int64(id), version: version, tags: theTags, timestampEdited: 0, position: position)
        return n
    }
//    public func asNode() -> Node {
//        return Node(id: id, version: version, tags: tags, timestampEdited: 0, position: )
//        
//    }
}
