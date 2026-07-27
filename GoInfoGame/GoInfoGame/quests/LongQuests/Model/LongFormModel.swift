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

// MARK: - LongFormResponse
struct LongFormResponse: Decodable {
    let version: String?
    let elements: [LongFormElement]
    let recencyPeriod: Int?
    let featurePresets: [FeaturePreset]?
    let customIcons: [CustomIcon]?

    init(from decoder: Decoder) throws {
        // Try top-level array first
        if let topArray = try? [LongFormElement](from: decoder) {
            self.elements = topArray
            self.version = nil
            self.recencyPeriod = nil
            self.featurePresets = nil
            self.customIcons = nil
            return
        }

        // Try decoding from "elements" key in dictionary
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.elements = try container.decode([LongFormElement].self, forKey: .elements)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.recencyPeriod = try container.decodeIfPresent(Int.self, forKey: .recencyPeriod)
        self.featurePresets = try container.decodeIfPresent([FeaturePreset].self, forKey: .featurePresets)
        self.customIcons = try container.decodeIfPresent([CustomIcon].self, forKey: .customIcons)
    }

    enum CodingKeys: String, CodingKey {
        case elements
        case version
        case recencyPeriod = "recency_period"
        case featurePresets = "feature-presets"
        case customIcons = "custom-icons"
    }
}

// MARK: - FeaturePreset
/// One selectable option in the "Add Feature" picker — e.g. Street light, Bench,
/// Subway. `tags` are applied verbatim to the OSM node created on submission.
struct FeaturePreset: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String
    let icon: String
    let tags: [String: String]

    enum CodingKeys: String, CodingKey {
        case name, icon, tags
    }

    static func == (lhs: FeaturePreset, rhs: FeaturePreset) -> Bool {
        lhs.name == rhs.name && lhs.icon == rhs.icon && lhs.tags == rhs.tags
    }
}

// MARK: - CustomIcon
/// Fallback for a `FeaturePreset.icon` that has no matching entry in the asset
/// catalog — downloaded from `url` and cached in place of the local image.
struct CustomIcon: Codable, Equatable {
    let name: String
    let url: String
    let type: String
}

// MARK: - Element
struct LongFormElement: Codable {
    let elementType, questQuery: String
    let elementTypeIcon: String?
    let quests: [LongQuest]

    enum CodingKeys: String, CodingKey {
        case elementType = "element_type"
        case elementTypeIcon = "element_type_icon"
        case questQuery = "quest_query"
        case quests
    }
}

// MARK: - Quest
struct LongQuest: Codable, Identifiable {
    let id =  UUID()
    var questID: Int
    var questTitle, questDescription: String
    var questType: QuestType?
    var questTag: String?
    var autoCaptureAttributes: [String: String]?
    var questAnswerChoices: [QuestAnswerChoice]?
    var questImageURL: String?
    var questAnswerValidation: QuestAnswerValidation?
    var questAnswerDependency: [QuestAnswerDependency]?
    var questUserAnswer : String?

    enum CodingKeys: String, CodingKey {
        case questID = "quest_id"
        case questTitle = "quest_title"
        case questDescription = "quest_description"
        case questType = "quest_type"
        case questTag = "quest_tag"
        case autoCaptureAttributes = "auto_capture_attributes"
        case questAnswerChoices = "quest_answer_choices"
        case questImageURL = "quest_image_url"
        case questAnswerValidation = "quest_answer_validation"
        case questAnswerDependency = "quest_answer_dependency"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questID = try container.decode(Int.self, forKey: .questID)
        questTitle = try container.decode(String.self, forKey: .questTitle)
        questDescription = try container.decode(String.self, forKey: .questDescription)
        questType = try? container.decode(QuestType.self, forKey: .questType)
        questTag = try? container.decode(String.self, forKey: .questTag)
        autoCaptureAttributes = try container.decodeIfPresent([String: String].self, forKey: .autoCaptureAttributes)
        questAnswerChoices = try container.decodeIfPresent([QuestAnswerChoice].self, forKey: .questAnswerChoices)
        questImageURL = try container.decodeIfPresent(String.self, forKey: .questImageURL)
        questAnswerValidation = try container.decodeIfPresent(QuestAnswerValidation.self, forKey: .questAnswerValidation)
        
        // Handle questAnswerDependency which can be an object or an array
        if let singleDependency = try? container.decodeIfPresent(QuestAnswerDependency.self, forKey: .questAnswerDependency) {
            questAnswerDependency = [singleDependency]
        } else if let multipleDependencies = try? container.decodeIfPresent([QuestAnswerDependency].self, forKey: .questAnswerDependency) {
            questAnswerDependency = multipleDependencies
        } else {
            questAnswerDependency = nil
        }
    }
    
    func getQuestTitleVoiceOver() -> String {
        if questType == .exclusiveChoice {
            return questTitle + "Only one item can be selected."
        } else if questType == .multipleChoice {
            return questTitle + "Multiple items can be selected."
        } else {
            return questTitle
        }
    }
}

// MARK: - QuestAnswerChoice
struct QuestAnswerChoice: Codable, Identifiable, Equatable {
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

// MARK: - QuestAnswerValidation
struct QuestAnswerValidation: Codable {
    let min: Int
}

// MARK: - QuestAnswerDependency
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
    case multipleChoice = "MultipleChoice"
    case textEntry = "TextEntry"
    case autoCapture = "AutoCapture"
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
