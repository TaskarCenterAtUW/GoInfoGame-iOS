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
    let tdeiProjectGroupId: String?
    let createdAt: String?
    let overrideConflicts: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "osw"
        externalAppAccess = try container.decode(Int.self, forKey: .externalAppAccess)
        imageryList = try container.decodeIfPresent(SatelliteServers.self, forKey: .imageryList)
        longFormQuest = try container.decodeIfPresent(LongFormResponse.self, forKey: .longFormQuest)
        tdeiProjectGroupId = try container.decodeIfPresent(String.self, forKey: .tdeiProjectGroupId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        overrideConflicts = try container.decodeIfPresent(Bool.self, forKey: .overrideConflicts) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case id, title, type, externalAppAccess, tdeiProjectGroupId, createdAt, overrideConflicts
        case imageryList = "imageryListDef"
        case longFormQuest = "longFormQuestDef"
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // Human-readable creation date shown under the workspace title, e.g. "Sep 12, 2025".
    var createdDateDisplay: String? {
        guard let createdAt else { return nil }
        guard let date = Workspace.iso8601WithFractionalSeconds.date(from: createdAt)
                ?? Workspace.iso8601.date(from: createdAt) else { return nil }
        return Workspace.displayDateFormatter.string(from: date)
    }
}

// MARK: - Polygon
class Polygon: Codable {

    init() {
    }
}
