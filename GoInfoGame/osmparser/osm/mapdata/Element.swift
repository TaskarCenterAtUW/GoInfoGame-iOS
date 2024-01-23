//
//  Element.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/3/24.
//

import Foundation

public enum ElementType: String, Codable {
    case node
    case way
    case relation
}

public protocol Element : Codable {
    var id: Int64 {get}
    var version : Int {get}
    var tags: [String:String] {get}
    var timestampEdited: Int64 {get}
    var type: ElementType {get}
}

public class LatLon: Codable {
    
    public let latitude: Double
    
   public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        Self.checkValidity(latitude: latitude, longitude: longitude)
        self.latitude = latitude
        self.longitude = longitude
    }
    static func checkValidity(latitude: Double, longitude: Double) {
        precondition(latitude >= -90.0 && latitude <= +90 && longitude <= +180 && longitude >= -180, "Latitude \(latitude), longitude \(longitude) is not a valid position")
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
    }
    
}

class DiffElement : Codable {
    let type: ElementType
    let clientId: Int64
    let serverId: Int64?
    let serverVersion: Int?
    
    init(type: ElementType, clientId: Int64, serverId: Int64? = nil, serverVersion: Int? = nil) {
        self.type = type
        self.clientId = clientId
        self.serverId = serverId
        self.serverVersion = serverVersion
    }
}

class RelationMember: Codable {
    let elementType: ElementType
    let ref: Int64
    let role: String
}


class Relation: Element {
    var id: Int64
    
    var version: Int
    
    var tags: [String : String] = [:]
    
    var timestampEdited: Int64 = 1
    
    var type: ElementType = .relation
    
    let members: [RelationMember]
    init(id: Int64, version: Int, tags: [String : String], timestampEdited: Int64, type: ElementType, members: [RelationMember]) {
        self.id = id
        self.version = version
        self.tags = tags
        self.timestampEdited = timestampEdited
        self.type = type
        self.members = members
    }
    
}

class Way: Element {
    var id: Int64
    
    var version: Int
    
    var tags: [String : String]
    
    var timestampEdited: Int64
    
    var type: ElementType = .way
    
    var nodeIds: [Int64] = []
    
    var isClosed: Bool {
        nodeIds.count >= 3 && nodeIds.first == nodeIds.last
    }
    init(id: Int64, version: Int, tags: [String : String], timestampEdited: Int64, type: ElementType, nodeIds: [Int64]) {
        self.id = id
        self.version = version
        self.tags = tags
        self.timestampEdited = timestampEdited
        self.type = type
        self.nodeIds = nodeIds
    }
    
}

public class Node : Element {
    public var id: Int64
    
    public var version: Int
    
    public var tags: [String : String]
    
    public var timestampEdited: Int64
    
    public var type: ElementType = .node
    
    let position: LatLon
    
   public init(id: Int64, version: Int, tags: [String : String], timestampEdited: Int64, position: LatLon, type: ElementType = .node) {
        self.id = id
        self.version = version
        self.tags = tags
        self.timestampEdited = timestampEdited
        self.type = type
        self.position = position
    }
    
}
