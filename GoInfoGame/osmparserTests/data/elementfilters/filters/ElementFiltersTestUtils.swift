//
//  ElementFiltersTestUtils.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/3/24.
//

import Foundation
@testable import osmparser

extension ElementFilter {
    func matches(tags:[String:String]) -> Bool{
        let node = TestDataShortcuts.node(tags: tags)
        do {
            return try matches(obj: node)
        } catch let e {
            return false
        }
    }
}

class TestDataShortcuts {
    
    static func epochMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970)
    }
    
    static func node(id:Int64 = 1, pos: LatLon = TestDataShortcuts.pos(), tags: [String:String], version: Int = 1, timestamp: Int64? = nil) -> Node {
        return Node(id: id, version: version, tags: tags, timestampEdited: timestamp ?? epochMillis(), position: pos)
    }
    
    static func pos(lat: Double = 0.0, lon: Double = 0.0 ) -> LatLon {
        return LatLon(latitude: lat, longitude: lon)
    }
    
    static func way(id:Int64 = 1, nodes:[Int64] = [], tags: [String:String] = [:], version: Int = 1, timestamp: Int64? = nil)-> Way{
        return Way(id: id, version: version, tags: tags, timestampEdited: timestamp ?? epochMillis(), type: .way, nodeIds: nodes)
    }
    /*
     id: Long = 1,
        members: List<RelationMember> = listOf(),
        tags: Map<String, String> = emptyMap(),
        version: Int = 1,
        timestamp: Long? = null
     */
    static func rel(id:Int64 = 1, members:[RelationMember]=[], tags:[String:String] = [:], version: Int = 1, timestamp :Int64? = nil )-> Relation {
        return Relation(id: id, version: version, tags: tags, timestampEdited: timestamp ?? epochMillis(), type: .relation, members: members)
    }
    
    
    
}
