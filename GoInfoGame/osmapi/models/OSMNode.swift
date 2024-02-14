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
public struct OSMNode: Codable, OSMPayload, OSMElement {
    public var tags: [String : String]
    public var isInteresting: Bool? = false
    public var isSkippable: Bool? = false
    
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
    
    public let type: String
    public let id: Int
    public let lat, lon: Double
    public let timestamp: Date
    public var version: Int
    public var changeset: Int
    public let user: String
    public let uid: Int
    
    public init(type: String, id: Int, lat: Double, lon: Double, timestamp: Date, version: Int, changeset: Int, user: String, uid: Int, tags: [String : String] = [:]) {
        self.type = type
        self.id = id
        self.lat = lat
        self.lon = lon
        self.timestamp = timestamp
        self.version = version
        self.changeset = changeset
        self.user = user
        self.uid = uid
        self.tags = tags
    }
}
