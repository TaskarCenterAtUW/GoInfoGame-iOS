//
//  WorkspacesResponse.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let workSpacesResponse = try? JSONDecoder().decode(WorkSpacesResponse.self, from: jsonData)

import Foundation

// MARK: - WorkSpacesResponse
class WorkSpacesResponse: Codable {
    let workspaces: [Workspace]

    init(workspaces: [Workspace]) {
        self.workspaces = workspaces
    }
}

// MARK: - Workspace
class Workspace: Codable, CustomStringConvertible {
    let id: String
    let posmBasePath: String
    let name: String
    let polygon: Polygon
    let quests: [Int]

    init(id: String, posmBasePath: String, name: String, polygon: Polygon, quests: [Int]) {
        self.id = id
        self.posmBasePath = posmBasePath
        self.name = name
        self.polygon = polygon
        self.quests = quests
    }
    var description: String {
        var d = "{ \n"
        d += "name: \(self.name) \n"
        d += "posmBasePath: \(self.posmBasePath) \n"
        d += "id: \(self.id) \n"
        d += "}\n"
        
        return  d
    }
}

// MARK: - Polygon
class Polygon: Codable {

    init() {
    }
}
