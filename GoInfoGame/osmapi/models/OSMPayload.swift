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
protocol OSMCreatePayload {
    func toCreatePayload() -> String
}
struct TagPayload: OSMPayload {
    let key:String
    var value:String
    
    func toPayload() -> String {
        return "<tag k=\"\(key)\" v=\"\(escapeValue())\"/>"
    }
    
    // function to escape characters in the value
    func escapeValue() -> String {
        let escapedValue = value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
        return escapedValue
    }
}

struct WayNodePayload: OSMPayload{
    let nodeId: Int
    func toPayload() -> String {
        return "<nd ref=\"\(nodeId)\" />"
    }
}
