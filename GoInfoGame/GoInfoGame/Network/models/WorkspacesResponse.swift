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
struct Workspace: Codable,Hashable {
    let id: Int
    let title: String
    let type: String?
    let externalAppAccess: Int
    
    init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)
           id = try container.decode(Int.self, forKey: .id)
           title = try container.decode(String.self, forKey: .title)
           type = try container.decodeIfPresent(String.self, forKey: .type) ?? "osw"
        externalAppAccess = try container.decode(Int.self, forKey: .externalAppAccess)
       }

       enum CodingKeys: String, CodingKey {
           case id, title, type, externalAppAccess
       }
}

// MARK: - Polygon
class Polygon: Codable {

    init() {
    }
}
