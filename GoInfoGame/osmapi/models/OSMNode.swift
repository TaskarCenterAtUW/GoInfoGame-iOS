//
//  OSMNode.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation

// Representation of a single node
// MARK: - OSMNodeResponse
public struct OSMNodeResponse: Codable {
  public let version, generator, copyright: String
   public let attribution, license: String
   public let elements: [OSMNode]
}

// MARK: - Element
public struct OSMNode: Codable, OSMPayload, OSMElement, OSMCreatePayload {
    public var tags: [String : String]
    public var isInteresting: Bool? = false
    public var isSkippable: Bool? = false
    
    public func toCreatePayload(exclude_gig_tags: Bool) -> String {
        var osmNode = "<create>"
        let xmlBuilder = OSMXMLBuilder(rootName: "node")
        xmlBuilder.addAttribute(name: "id", value: "-1")
        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
        xmlBuilder.addAttribute(name: "changeset", value: "\(changeset)")
        tags.forEach { (key: String, value: String) in
            let tagNode = TagPayload(key: key, value: value)
            xmlBuilder.addChild(element: tagNode)
        }
        // Today date
        // Create a DateFormatter instance
        let dateFormatter = DateFormatter()

        // Set the date format to "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-ddXXX"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Create a Date object (for example, the current date)
        let currentDate = Date()

        // Convert the Date object to a formatted string
        let formattedDate = dateFormatter.string(from: currentDate)

        let builtString = xmlBuilder.buildXML(exclude_gig_tags: exclude_gig_tags)
        osmNode.append(builtString)
        osmNode.append("</create>")
        return osmNode

    }

    /// Builds an osmChange `<delete>` fragment for this node — used to undo a
    /// just-created feature outright, never for reverting a tag edit on a
    /// pre-existing element (that stays a `<modify>`, via `toPayload`).
    public func toDeletePayload() -> String {
        var osmNode = "<delete>"
        let xmlBuilder = OSMXMLBuilder(rootName: "node")
        xmlBuilder.addAttribute(name: "id", value: "\(id)")
        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
        xmlBuilder.addAttribute(name: "version", value: "\(version)")
        xmlBuilder.addAttribute(name: "changeset", value: "\(changeset)")
        let builtString = xmlBuilder.buildXML(exclude_gig_tags: true)
        osmNode.append(builtString)
        osmNode.append("</delete>")
        return osmNode
    }

    public func fetchInternalGigTags() -> [String:String] {

        var internalTags:[String:String] = [:]
        let dateFormatter = DateFormatter()

        // Set the date format to "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-ddXXX"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Create a Date object (for example, the current date)
        let currentDate = Date()

        // Convert the Date object to a formatted string
        let formattedDate = dateFormatter.string(from: currentDate)
        //"ext:gig_last_updated"
        internalTags["ext:gig_last_updated"] = formattedDate
        // ext:gig_complete is intentionally not managed by the app — the long
        // form's question set is configurable from the web and can change over
        // time, so a stamped completion flag can't be trusted to stay accurate.

        return internalTags
    }

    ///
    public func toPayload(exclude_gig_tags: Bool = false) -> String {
         var osmNode = "<modify>"
         let xmlBuilder = OSMXMLBuilder(rootName: "node")
         xmlBuilder.addAttribute(name: "id", value: "\(id)")
        xmlBuilder.addAttribute(name: "lat", value: "\(lat)")
        xmlBuilder.addAttribute(name: "lon", value: "\(lon)")
         xmlBuilder.addAttribute(name: "version", value: "\(version)")
         xmlBuilder.addAttribute(name: "changeset", value: "\(changeset)")

        // Add the gig payload tags. ext:gig_last_updated is held back here (not
        // added to xmlBuilder yet) rather than added-then-"updated" — TagPayload
        // is a struct, so addChild(element:) below would otherwise copy its value
        // in at that moment; mutating a *different* local copy afterwards (as this
        // used to do) never reaches the copy already sitting in the builder, so a
        // re-answered element's date silently kept its original value.
        // ext:gig_complete is left alone entirely — the app doesn't write or
        // strip it, so any existing value simply passes through like any other tag.
         tags.forEach { (key: String, value: String) in
             if !exclude_gig_tags {
                 if (key == "ext:gig_last_updated"){
                     return // always replaced with today's date below — the old value is never needed
                 }
             }
             xmlBuilder.addChild(element: TagPayload(key: key, value: value))
         }

        // Today date
        // Create a DateFormatter instance
        let dateFormatter = DateFormatter()

        // Set the date format to "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-ddXXX"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Create a Date object (for example, the current date)
        let currentDate = Date()

        // Convert the Date object to a formatted string
        let formattedDate = dateFormatter.string(from: currentDate)

        if !exclude_gig_tags {
            let gigLastUpdated = TagPayload(key: "ext:gig_last_updated", value: formattedDate)
            xmlBuilder.addChild(element: gigLastUpdated)
        }
        
 
        let builtString = xmlBuilder.buildXML(exclude_gig_tags: exclude_gig_tags)
         osmNode.append(builtString)
         osmNode.append("</modify>")
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
