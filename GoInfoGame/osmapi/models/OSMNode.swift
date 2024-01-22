//
//  OSMNode.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation

// Representation of a single node
// MARK: - OSMNodeResponse
struct OSMNodeResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let elements: [OSMNode]
}

// MARK: - Element
struct OSMNode: Codable, OSMPayload {
    
    func toPayload() -> String {
         var osmNode = "<osm>"
        let xmlBuilder = OSMXMLBuilder(rootName: "node")
        xmlBuilder.addAttribute(name: "id", value: "\(id)")
        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
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
    let lat, lon: Double
    let timestamp: Date
    let version, changeset: Int
    let user: String
    let uid: Int
    let tags: [String:String]
}
