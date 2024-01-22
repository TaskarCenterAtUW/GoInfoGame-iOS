//
//  OSMWay.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
//import Foundation

// MARK: - OSMWayResponse
struct OSMWayResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let elements: [OSMWay]
}

// MARK: - Element
struct OSMWay: Codable, OSMPayload  {
    func toPayload() -> String {
         var osmNode = "<osm>"
        let xmlBuilder = OSMXMLBuilder(rootName: "way")
        xmlBuilder.addAttribute(name: "id", value: "\(id)")
//        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
//        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
        xmlBuilder.addAttribute(name: "version", value: "\(version)")
        xmlBuilder.addAttribute(name: "changeset", value: "\(changeset)")
        tags.forEach { (key: String, value: String) in
            let tagNode = TagPayload(key: key, value: value)
            xmlBuilder.addChild(element: tagNode)
        }
        let builtString = xmlBuilder.buildXML()
        osmNode.append(builtString)
        osmNode.append("</osm>")
        return osmNode
    }
    
    let type: String
    let id: Int
    let timestamp: Date
    let version: Int
    var changeset: Int
    let user: String
    let uid: Int
    let nodes: [Int]
    var tags: [String:String]
}
