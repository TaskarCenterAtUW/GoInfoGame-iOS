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
struct Workspace: Codable, CustomStringConvertible,Hashable {
    let id: Int
    let title: String
    let tdeiRecordId:String
    let tdeiProjectGroupId:String
    let tdeiServiceId: String
    let tdeiMetadata: String
    
    init(id: Int, title: String, tdeiRecordId:String,tdeiProjectGroupId:String,tdeiServiceId: String,tdeiMetadata: String, quests: [Int]) {
        self.id = id
        self.title = title
        self.tdeiRecordId = tdeiRecordId
        self.tdeiProjectGroupId = tdeiProjectGroupId
        self.tdeiServiceId = tdeiServiceId
        self.tdeiMetadata = tdeiMetadata
        
    }

    var description: String {
        var d = "{ \n"
        d += "name: \(self.title) \n"
        d += "id: \(self.id) \n"
        d += "}\n"
        return d
    }
}

// MARK: - Polygon
class Polygon: Codable {

    init() {
    }
}
