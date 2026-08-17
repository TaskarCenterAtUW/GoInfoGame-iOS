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
    
    /// Neither ext:gig_complete nor ext:gig_last_updated is managed by the app —
    /// completeness and recency are both computed live (from actual answers and
    /// the OSM element's own native `timestamp`, respectively) rather than cached
    /// in a tag, since the long form's question set is configurable from the web
    /// and can change over time. Any pre-existing value for either tag simply
    /// passes through unchanged, like any other tag.
    public func toPayload(exclude_gig_tags: Bool = false) -> String {
        var osmNode = "<modify>"
        let xmlBuilder = OSMXMLBuilder(rootName: "way")
        xmlBuilder.addAttribute(name: "id", value: "\(id)")
        //        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
        //        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
        xmlBuilder.addAttribute(name: "version", value: "\(version)")
        xmlBuilder.addAttribute(name: "changeset", value: "\(changeset)")

        tags.forEach { (key: String, value: String) in
            // See the equivalent comment in OSMNode.toPayload: an empty value means
            // "this tag was cleared, remove it" — omitting it from the <modify> is
            // the only valid way to signal a tag removal to the OSM API.
            guard !value.isEmpty else { return }
            xmlBuilder.addChild(element: TagPayload(key: key, value: value))
        }

       nodes.forEach { nodeId in
           let wayNode = WayNodePayload(nodeId: nodeId)
           xmlBuilder.addChild(element: wayNode)
       }
        let builtString = xmlBuilder.buildXML(exclude_gig_tags: exclude_gig_tags)
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
