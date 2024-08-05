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
    var requiredValue: [String]
    
    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case requiredValue = "required_value"
    }
}

enum QuestType: String, Codable {
    case exclusiveChoice = "ExclusiveChoice"
    case numeric = "Numeric"
    case excWithImg = "ExclusiveChoiceWithImg"
}

let dummyFormDataS = LongFormModel(
    elementType: "Sidewalks",
    questQuery: "highway=footway and footway=sidewalk",
    quests: [
        LongQuest(
            questID: 1,
            questTitle: "What type of surface is the sidewalk?",
            questDescription: "Choose the type of surface of the sidewalk",
            questType: .excWithImg,
            questTag: "surface",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "asphalt",
                    choiceText: "Asphalt",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "concrete",
                    choiceText: "Concrete",
                    imageURL: "surface_compacted",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "brick",
                    choiceText: "Rock",
                    imageURL: "surface_rock",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "sand",
                    choiceText: "Sand",
                    imageURL: "surface_sand",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "sett",
                    choiceText: "Sett",
                    imageURL: "surface_sett",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "paved",
                    choiceText: "Paved",
                    imageURL: "surface_paved",
                    choiceFollowUp: nil
                )

            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 2,
            questTitle: "Are there small surface cracks or disruptions?",
            questDescription: "Identify if there are any cracks or disruptions in the sidewalk surface that are smaller than 3 inch vertical or horizontal displacement, or smaller than 3 inch gaps",
            questType: .exclusiveChoice,
            questTag: "small_surface_cracks",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "1-5",
                    choiceText: "1-5 small cracks or disruptions along this sidewalk",
                    imageURL: nil,
                    choiceFollowUp: "Please take a picture of the largest disruption in this sidewalk"
                ),
                QuestAnswerChoice(
                    value: "6-10",
                    choiceText: "6-10 small cracks or disruptions along this sidewalk",
                    imageURL: nil,
                    choiceFollowUp: "Please take a picture of the largest disruption in this sidewalk"
                ),
                QuestAnswerChoice(
                    value: ">10",
                    choiceText: "more than 10 small cracks or disruptions along this sidewalk",
                    imageURL: nil,
                    choiceFollowUp: "Please take a picture of the largest disruption in this sidewalk"
                )
            ],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 3,
            questTitle: "Are there large surface cracks, large disruptions, tree uproots, or large gaps in the sidewalk?",
            questDescription: "Identify if there are any large surface disruptions (greater than 3 inches in any direction) in the sidewalk surface",
            questType: .exclusiveChoice,
            questTag: "large_surface_cracks",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "0",
                    choiceText: "No",
                    imageURL: nil,
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "<5",
                    choiceText: "1-5 large disruptions or gaps along this sidewalk",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: "Please take a picture of the largest disruption in this sidewalk"
                ),
                QuestAnswerChoice(
                    value: "<10",
                    choiceText: "6-10 large disruptions or gaps along this sidewalk",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: "Please take a picture of the largest disruption in this sidewalk"
                ),
                QuestAnswerChoice(
                    value: ">10",
                    choiceText: "more than 10 large disruptions or gaps along this sidewalk",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: "Please take a picture of the largest disruption in this sidewalk"
                )
            ],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 4,
            questTitle: "Is the sidewalk complete along the entire block?",
            questDescription: "Check if the sidewalk extends continuously along the entire block",
            questType: .exclusiveChoice,
            questTag: "sidewalk_complete",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: "Please take a picture of the gap or missing sidewalk"
                )
            ],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 5,
            questTitle: "Does the sidewalk narrow?",
            questDescription: "Identify if there are any sections where the sidewalk narrows",
            questType: .exclusiveChoice,
            questTag: "sidewalk_narrows",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: "Please take a picture of the narrowest place on this sidewalk"
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "http://some_url.com/image.jpg",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 6,
            questTitle: "How many driveways intersect the sidewalk?",
            questDescription: "Enter the number of driveways that intersect the sidewalk",
            questType: .numeric,
            questTag: "driveways",
            questAnswerChoices: [],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: QuestAnswerValidation(
                min: 0
            ),
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 7,
            questTitle: "How many light poles are along the sidewalk?",
            questDescription: "Enter the number of light poles along the sidewalk",
            questType: .numeric,
            questTag: "light_poles",
            questAnswerChoices: [],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: QuestAnswerValidation(
                min: 0
            ),
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 8,
            questTitle: "How many manholes are on the sidewalk?",
            questDescription: "Enter the number of manholes on the sidewalk",
            questType: .numeric,
            questTag: "manholes",
            questAnswerChoices: [],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: QuestAnswerValidation(
                min: 0
            ),
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 9,
            questTitle: "Is there a crossing in the middle of this block?",
            questDescription: "Check if there is a pedestrian crossing in the middle of the block",
            questType: .exclusiveChoice,
            questTag: "midblock_crossing",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: nil,
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: nil,
                    choiceFollowUp: nil
                )
            ],
            questImageURL: "http://some_url.com/image.jpg",
            questAnswerValidation: nil,
            questAnswerDependency: nil
        )
    ]
)

let dummyQuests: [LongQuest] = [
      LongQuest(
          questID: 1,
          questTitle: "Is there a traffic island directly reachable from this curb?",
          questDescription: "Check if there is a traffic island directly reachable from this curbpoint",
          questType: .exclusiveChoice,
          questTag: "traffic_island",
          questAnswerChoices: [
              QuestAnswerChoice(value: "yes", choiceText: "Yes", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "no", choiceText: "No", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: nil
      ),
      LongQuest(
          questID: 2,
          questTitle: "Is there a roundabout or traffic circle at this intersection?",
          questDescription: "Check if there is a roundabout at this intersection",
          questType: .exclusiveChoice,
          questTag: "traffic_circle",
          questAnswerChoices: [
              QuestAnswerChoice(value: "yes", choiceText: "Yes", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "no", choiceText: "No", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: nil
      ),
      LongQuest(
          questID: 3,
          questTitle: "Is there a curb extension at this corner?",
          questDescription: "Check if there is a curb extension at this corner",
          questType: .exclusiveChoice,
          questTag: "curb_extension",
          questAnswerChoices: [
              QuestAnswerChoice(value: "yes", choiceText: "Yes", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "no", choiceText: "No", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: nil
      ),
      LongQuest(
          questID: 4,
          questTitle: "Are there 0, 1 or 2 curb cuts at this corner?",
          questDescription: "Indicate if there are 1 or 2 curb cuts at this corner",
          questType: .exclusiveChoice,
          questTag: "curb_cuts",
          questAnswerChoices: [
              QuestAnswerChoice(value: "0", choiceText: "No Curb ramps here", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "1", choiceText: "1", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "2", choiceText: "2", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: nil
      ),
      LongQuest(
          questID: 5,
          questTitle: "If there is 1, is it facing only one side of the street, or is the curb ramp facing toward the middle of the intersection?",
          questDescription: "Specify the orientation of the single curb cut",
          questType: .exclusiveChoice,
          questTag: "curb_cut_orientation",
          questAnswerChoices: [
              QuestAnswerChoice(value: "one_side", choiceText: "One side of the street", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "middle_intersection", choiceText: "Middle of the intersection", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: QuestAnswerDependency(questionID: 4, requiredValue: ["1"])
      ),
      LongQuest(
          questID: 6,
          questTitle: "If there is a curb cut, is there tactile paving on this curb cut?",
          questDescription: "Check if there is tactile paving on the curb cut",
          questType: .exclusiveChoice,
          questTag: "tactile_paving",
          questAnswerChoices: [
              QuestAnswerChoice(value: "yes", choiceText: "Yes", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "no", choiceText: "No", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: QuestAnswerDependency(questionID: 4, requiredValue: ["1", "2"])
      ),
      LongQuest(
          questID: 7,
          questTitle: "If there are no curb cuts, is there a raised curb here or is it flush with the street?",
          questDescription: "Specify if the curb is raised or flush with the street when there are no curb cuts",
          questType: .exclusiveChoice,
          questTag: "curb_status",
          questAnswerChoices: [
              QuestAnswerChoice(value: "raised", choiceText: "Raised", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "flush", choiceText: "Flush", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: QuestAnswerDependency(questionID: 4, requiredValue: ["0"])
      ),
      LongQuest(
          questID: 8,
          questTitle: "Is there a bike lane immediately after you get off the curb at this corner?",
          questDescription: "Check if there is a bike lane immediately after the curb",
          questType: .exclusiveChoice,
          questTag: "bike_lane",
          questAnswerChoices: [
              QuestAnswerChoice(value: "yes", choiceText: "Yes", imageURL: "surface_asphalt", choiceFollowUp: nil),
              QuestAnswerChoice(value: "no", choiceText: "No", imageURL: "surface_asphalt", choiceFollowUp: nil)
          ],
          questImageURL: nil,
          questAnswerValidation: nil,
          questAnswerDependency: nil
      )
  ]



let dummyFormData = LongFormModel(
    elementType: "Kerb",
    questQuery: "barrier=kerb",
    quests: [
        LongQuest(
            questID: 1,
            questTitle: "Is there a traffic island directly reachable from this curb?",
            questDescription: "Check if there is a traffic island directly reachable from this curbpoint",
            questType: .exclusiveChoice,
            questTag: "traffic_island",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 2,
            questTitle: "Is there a roundabout or traffic circle at this intersection?",
            questDescription: "Check if there is a roundabout at this intersection",
            questType: .exclusiveChoice,
            questTag: "traffic_circle",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 3,
            questTitle: "Is there a curb extension at this corner?",
            questDescription: "Check if there is a curb extension at this corner",
            questType: .exclusiveChoice,
            questTag: "curb_extension",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 4,
            questTitle: "Are there 0, 1 or 2 curb cuts at this corner?",
            questDescription: "Indicate if there are 1 or 2 curb cuts at this corner",
            questType: .exclusiveChoice,
            questTag: "curb_cuts",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "0",
                    choiceText: "No Curb ramps here",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "1",
                    choiceText: "1",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "2",
                    choiceText: "2",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: nil
        ),
        LongQuest(
            questID: 5,
            questTitle: "If there is 1, is it facing only one side of the street, or is the curb ramp facing toward the middle of the intersection?",
            questDescription: "Specify the orientation of the single curb cut",
            questType: .exclusiveChoice,
            questTag: "curb_cut_orientation",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "one_side",
                    choiceText: "One side of the street",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "middle_intersection",
                    choiceText: "Middle of the intersection",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: QuestAnswerDependency(
                questionID: 4,
                requiredValue: ["1"]
            )
        ),
        LongQuest(
            questID: 6,
            questTitle: "If there is a curb cut, is there tactile paving on this curb cut?",
            questDescription: "Check if there is tactile paving on the curb cut",
            questType: .exclusiveChoice,
            questTag: "tactile_paving",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: QuestAnswerDependency(
                questionID: 4,
                requiredValue: ["1", "2"]
            )
        ),
        LongQuest(
            questID: 7,
            questTitle: "If there are no curb cuts, is there a raised curb here or is it flush with the street?",
            questDescription: "Specify if the curb is raised or flush with the street when there are no curb cuts",
            questType: .exclusiveChoice,
            questTag: "curb_status",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "raised",
                    choiceText: "Raised",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "flush",
                    choiceText: "Flush",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: QuestAnswerDependency(
                questionID: 4,
                requiredValue: ["0"]
            )
        ),
        LongQuest(
            questID: 8,
            questTitle: "Is there a bike lane immediately after you get off the curb at this corner?",
            questDescription: "Check if there is a bike lane immediately after the curb",
            questType: .exclusiveChoice,
            questTag: "bike_lane",
            questAnswerChoices: [
                QuestAnswerChoice(
                    value: "yes",
                    choiceText: "Yes",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                ),
                QuestAnswerChoice(
                    value: "no",
                    choiceText: "No",
                    imageURL: "surface_asphalt",
                    choiceFollowUp: nil
                )
            ],
            questImageURL: nil,
            questAnswerValidation: nil,
            questAnswerDependency: nil
        )
    ]
)





