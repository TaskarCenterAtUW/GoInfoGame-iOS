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
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Create a Date object (for example, the current date)
        let currentDate = Date()

        // Convert the Date object to a formatted string
        let formattedDate = dateFormatter.string(from: currentDate)

        let builtString = xmlBuilder.buildXML(exclude_gig_tags: exclude_gig_tags)
        osmNode.append(builtString)
        osmNode.append("</create>")
        return osmNode
         
    }
    
    public func fetchInternalGigTags() -> [String:String] {
        
        var internalTags:[String:String] = [:]
        let dateFormatter = DateFormatter()

        // Set the date format to "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Create a Date object (for example, the current date)
        let currentDate = Date()

        // Convert the Date object to a formatted string
        let formattedDate = dateFormatter.string(from: currentDate)
        //"ext:gig_last_updated"
        internalTags["ext:gig_last_updated"] = formattedDate
        internalTags["ext:gig_complete"] = "yes"
        
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
        
        // Add the gig payload tags.
        var existingGigComplete: TagPayload? = nil
        var existingGigUpdate: TagPayload? = nil
         tags.forEach { (key: String, value: String) in
             let tagNode = TagPayload(key: key, value: value)
             if !exclude_gig_tags {
                 if (key == "ext:gig_complete"){
                     existingGigComplete = tagNode
                 }
                 if (key == "ext:gig_last_updated"){
                     existingGigUpdate = tagNode
                 }
             }
             
             xmlBuilder.addChild(element: tagNode)
         }
        
        if !exclude_gig_tags {
            if existingGigComplete == nil {
                let gigCompleteTag = TagPayload(key: "ext:gig_complete", value: "yes")
                xmlBuilder.addChild(element: gigCompleteTag)
            }
        }

        // Today date
        // Create a DateFormatter instance
        let dateFormatter = DateFormatter()

        // Set the date format to "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Create a Date object (for example, the current date)
        let currentDate = Date()

        // Convert the Date object to a formatted string
        let formattedDate = dateFormatter.string(from: currentDate)
        
        if !exclude_gig_tags {
            if existingGigUpdate == nil{
                let gigLastUpdated = TagPayload(key: "ext:gig_last_updated", value: formattedDate)
                xmlBuilder.addChild(element: gigLastUpdated)
            }
            else {
                existingGigUpdate!.value = formattedDate
            }
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
