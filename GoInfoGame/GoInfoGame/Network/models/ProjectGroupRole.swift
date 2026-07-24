//
//  ProjectGroupRole.swift
//  GoInfoGame
//

import Foundation

struct ProjectGroupRole: Decodable {
    let tdeiProjectGroupId: String
    let projectGroupName: String

    enum CodingKeys: String, CodingKey {
        case tdeiProjectGroupId = "tdei_project_group_id"
        case projectGroupName = "project_group_name"
    }
}
