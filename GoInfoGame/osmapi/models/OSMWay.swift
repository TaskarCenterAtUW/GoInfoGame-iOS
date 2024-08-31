//
//  OSMWay.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
//import Foundation

// MARK: - OSMWayResponse
public struct OSMWayResponse: Codable {
   public let version, generator, copyright: String
   public let attribution, license: String
   public let elements: [OSMWay]
}

// MARK: - Element
public struct OSMWay: Codable, OSMPayload, OSMElement  {
    public var isInteresting: Bool? = false
    public var isSkippable: Bool? = false
   public func toPayload() -> String {
        var osmNode = "<modify>"
        let xmlBuilder = OSMXMLBuilder(rootName: "way")
        xmlBuilder.addAttribute(name: "id", value: "\(id)")
        //        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
        //        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
        xmlBuilder.addAttribute(name: "version", value: "\(version)")
        xmlBuilder.addAttribute(name: "changeset", value: "\(changeset)")
       
       // Add the gig payload tags.
       
        tags.forEach { (key: String, value: String) in
            let tagNode = TagPayload(key: key, value: value)
            xmlBuilder.addChild(element: tagNode)
        }
       let gigCompleteTag = TagPayload(key: "ext:gig_complete", value: "yes")
       // Today date
       // Create a DateFormatter instance
       let dateFormatter = DateFormatter()

       // Set the date format to "yyyy-MM-dd"
       dateFormatter.dateFormat = "yyyy-MM-dd"

       // Create a Date object (for example, the current date)
       let currentDate = Date()

       // Convert the Date object to a formatted string
       let formattedDate = dateFormatter.string(from: currentDate)

       let gigLastUpdated = TagPayload(key: "ext:gig_last_updated", value: formattedDate)
       xmlBuilder.addChild(element: gigCompleteTag)
       xmlBuilder.addChild(element: gigLastUpdated)
       
       nodes.forEach { nodeId in
           let wayNode = WayNodePayload(nodeId: nodeId)
           xmlBuilder.addChild(element: wayNode)
       }
        let builtString = xmlBuilder.buildXML()
        osmNode.append(builtString)
        osmNode.append("</modify>")
        return osmNode
    }
    
    public let type: String
    public let id: Int
    public let timestamp: Date
    public var version: Int
    public var changeset: Int
    public let user: String
    public let uid: Int
    public let nodes: [Int]
    public var tags: [String:String]
    
    public init(type: String, id: Int, timestamp: Date, version: Int, changeset: Int, user: String, uid: Int, nodes: [Int], tags: [String : String]) {
        self.type = type
        self.id = id
        self.timestamp = timestamp
        self.version = version
        self.changeset = changeset
        self.user = user
        self.uid = uid
        self.nodes = nodes
        self.tags = tags
    }
}
