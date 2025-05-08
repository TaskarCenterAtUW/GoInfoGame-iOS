//
//  OSMPayload.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
import HTMLEntities

protocol OSMPayload {
    
    func toPayload(exclude_gig_tags: Bool) -> String
}
protocol OSMCreatePayload {
    func toCreatePayload(exclude_gig_tags: Bool) -> String
}
struct TagPayload: OSMPayload {
    let key:String
    var value:String
    
    func toPayload(exclude_gig_tags: Bool = false) -> String {
        let htmlEscapeValue = value.htmlEscape()
        return "<tag k=\"\(key)\" v=\"\(htmlEscapeValue)\"/>"
    }
}

struct WayNodePayload: OSMPayload{
    let nodeId: Int
    func toPayload(exclude_gig_tags: Bool = false) -> String {
        return "<nd ref=\"\(nodeId)\" />"
    }
}
