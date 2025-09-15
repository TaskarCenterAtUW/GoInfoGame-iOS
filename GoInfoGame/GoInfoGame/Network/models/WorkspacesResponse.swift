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
class WorkSpacesResponse: Decodable {
    let workspaces: [Workspace]

    init(workspaces: [Workspace]) {
        self.workspaces = workspaces
    }
}

// MARK: - Workspace
struct Workspace: Decodable {
    let id: Int
    let title: String
    let type: String?
    let externalAppAccess: Int
    let imageryList: SatelliteServers?
    let longFormQuest: LongFormResponse?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "osw"
        externalAppAccess = try container.decode(Int.self, forKey: .externalAppAccess)
        imageryList = try container.decodeIfPresent(SatelliteServers.self, forKey: .imageryList)
        longFormQuest = try container.decodeIfPresent(LongFormResponse.self, forKey: .longFormQuest)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, type, externalAppAccess
        case imageryList = "imageryListDef"
        case longFormQuest = "longFormQuestDef"
    }
    
//    static func == (lhs: Workspace, rhs: Workspace) -> Bool {
//        return lhs.id == rhs.id
//    }
    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(title)
//        hasher.combine(type)
//        hasher.combine(externalAppAccess)
//        hasher.combine(imageryList)
//    }
}

// MARK: - Polygon
class Polygon: Codable {

    init() {
    }
}
