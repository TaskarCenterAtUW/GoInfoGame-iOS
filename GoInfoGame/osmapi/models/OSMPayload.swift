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
    let value:String
    
    func toPayload() -> String {
         return "<tag k=\"\(key)\" v=\"\(value)\"/>"
    }
}
