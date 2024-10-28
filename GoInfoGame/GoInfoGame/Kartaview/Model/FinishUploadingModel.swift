//
//  FinishUploadingModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 28/10/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let finishUploadingModel = try? JSONDecoder().decode(FinishUploadingModel.self, from: jsonData)

import Foundation

// MARK: - FinishUploadingModel
struct FinishUploadingModel: Codable {
    let status: FUStatus
    let osv: FUOsv
}

// MARK: - Osv
struct FUOsv: Codable {
    let sequenceID: String

    enum CodingKeys: String, CodingKey {
        case sequenceID = "sequenceId"
    }
}

// MARK: - Status
struct FUStatus: Codable {
    let apiCode: Int
    let apiMessage: String
    let httpCode: Int
    let httpMessage: String
}
