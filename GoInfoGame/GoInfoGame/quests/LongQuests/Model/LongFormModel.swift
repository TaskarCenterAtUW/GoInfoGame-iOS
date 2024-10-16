//
//  LongFormModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 23/07/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let longFormModel = try? JSONDecoder().decode(LongFormModel.self, from: jsonData)

import Foundation

// MARK: - LongFormModelElement
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let longFormModel = try? JSONDecoder().decode(LongFormModel.self, from: jsonData)

import Foundation

struct LongFormModel: Codable {
    let elementType, questQuery: String
    let quests: [LongQuest]

    enum CodingKeys: String, CodingKey {
        case elementType = "element_type"
        case questQuery = "quest_query"
        case quests
    }
}

struct LongQuest: Codable, Identifiable {
    let id =  UUID()
    var questID: Int
    var questTitle, questDescription: String
    var questType: QuestType
    var questTag: String
    var questAnswerChoices: [QuestAnswerChoice]
    var questImageURL: String?
    var questAnswerValidation: QuestAnswerValidation?
    var questAnswerDependency: QuestAnswerDependency?
    var questUserAnswer : String?
    
    func getFormValue() ->[String:String?] {
        return [self.questTag:self.questUserAnswer]
    }

    enum CodingKeys: String, CodingKey {
        case questID = "quest_id"
        case questTitle = "quest_title"
        case questDescription = "quest_description"
        case questType = "quest_type"
        case questTag = "quest_tag"
        case questAnswerChoices = "quest_answer_choices"
        case questImageURL = "quest_image_url"
        case questAnswerValidation = "quest_answer_validation"
        case questAnswerDependency = "quest_answer_dependency"
    }
    
    func getQtype() -> QuestType {
        if (self.questType == .exclusiveChoice) {
            // Do the choice shit and get the type
        }
        else {
            return self.questType
        }
        // loop through choice images . If all are none, send back text type
        // If one or more is image, send back image
        return self.questType
    }
}

struct QuestAnswerChoice: Codable, Identifiable {
    let id = UUID()
    let value, choiceText: String
    let imageURL: String?
    let choiceFollowUp: String?

    enum CodingKeys: String, CodingKey {
        case value
        case choiceText = "choice_text"
        case imageURL = "image_url"
        case choiceFollowUp = "choice_follow_up"
    }
}

struct QuestAnswerValidation: Codable {
    let min: Int
}

struct QuestAnswerDependency: Codable {
    var questionID: Int
    var requiredValue: RequiredValue
    
    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case requiredValue = "required_value"
    }
}

enum QuestType: String, Codable {
    case exclusiveChoice = "ExclusiveChoice"
    case numeric = "Numeric"
//    case excWithImg = "ExclusiveChoiceWithImg"
}


enum RequiredValue: Codable {
    case string(String)
    case array([String])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(RequiredValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unexpected type for RequiredValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}







