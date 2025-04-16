//
//  OSMPayload.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
import HTMLEntities

protocol OSMPayload {
    
     func toPayload() -> String
}
protocol OSMCreatePayload {
    func toCreatePayload() -> String
}
struct TagPayload: OSMPayload {
    let key:String
    var value:String
    
    func toPayload() -> String {
        let htmlEscapeValue = value.htmlEscape()
        return "<tag k=\"\(key)\" v=\"\(htmlEscapeValue)\"/>"
    }
}

struct WayNodePayload: OSMPayload{
    let nodeId: Int
    func toPayload() -> String {
        return "<nd ref=\"\(nodeId)\" />"
    }
}
