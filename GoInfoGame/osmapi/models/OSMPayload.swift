//
//  OSMPayload.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
protocol OSMPayload {
    
     func toPayload() -> String
}

struct TagPayload: OSMPayload {
    let key:String
    var value:String
    
    func toPayload() -> String {
         return "<tag k=\"\(key)\" v=\"\(value)\"/>"
    }
}

struct WayNodePayload: OSMPayload{
    let nodeId: Int
    func toPayload() -> String {
        return "<nd ref=\"\(nodeId)\" />"
    }
}
