//
//  LongFormViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 02/08/24.
//

import Foundation

class LongFormViewModel: ObservableObject {
    var longForm: LongFormElement?
    @Published var selectedChoices: [Int: QuestAnswerChoice?] = [:]

    init() {}
        
     func shouldShowQuest(_ quest: LongQuest) -> Bool {
         guard let dependencies = quest.questAnswerDependency else {
             return true
         }
         var dependencyResult: Bool = true
         for dependency in dependencies {
             dependencyResult = dependencyResult && checkDependency(dependency)
             if !dependencyResult {
                 return dependencyResult
             }
         }
         return dependencyResult
    }
    
    func checkDependency(_ dependency: QuestAnswerDependency) -> Bool {
        if let answeredChoiceOptional = selectedChoices[dependency.questionID],
           let answeredChoice = answeredChoiceOptional,
           !answeredChoice.value.isEmpty {
            let answeredValues = answeredChoice.value.components(separatedBy: ", ")
            switch dependency.requiredValue {
            case .string(let reqValue):
                return answeredValues.contains(reqValue)
            case .array(let reqValue):
                // Check for any intersection between the two sets of values.
                let answeredSet = Set(answeredValues)
                let requiredSet = Set(reqValue)
                return !answeredSet.isDisjoint(with: requiredSet)
            }
            
        }
        return false
    }
    
    func clearAnswersForHiddenQuests() {
        guard let quests = longForm?.quests else { return }
        for quest in quests {
            if !shouldShowQuest(quest) {
                if selectedChoices[quest.questID] != nil {
                    selectedChoices[quest.questID] = nil
                }
            }
        }
    }
    
    func getAnswersForSubmission() -> [String: String] {
        var submissionDict: [String: String] = [:]
        guard let quests = longForm?.quests else { return [:] }
        let isLiDARSupportedDevice = LiDARDetection.shared.isLiDARSupported()
        for quest in quests {
            if let choiceOptional = selectedChoices[quest.questID], let choice = choiceOptional {
                if shouldShowQuest(quest) {
                    // Handle AutoCapture quest type
                    if quest.questType == .autoCapture {
                        handleAutoCaptureTags(choice: choice, submissionDict: &submissionDict)
                    } else {
                        submissionDict[quest.questTag] = choice.value
                    }
                }
            } else if isLiDARSupportedDevice,
                      let quest = quests.first(where: { $0.questID == quest.questID }),
                      quest.questType == .autoCapture {
                // AutoCapture quest not answered - mark as ignored
                submissionDict["ext:autoCapture:ignored"] = "yes"
            }
        }
        return submissionDict
    }
    
    // MARK: - AutoCapture Helper Methods
    
    private func handleAutoCaptureTags(choice: QuestAnswerChoice, submissionDict: inout [String: String]) {
        // Parse CSV data from choice.value
        // Format: "width_m:2.34,1.92|slope_deg:2.31,1.45|cross_slope_deg:1.5,2.3"
        
        let widthValues = extractCSVValues(from: choice.value, key: "width_m")
        let slopeValues = extractCSVValues(from: choice.value, key: "slope_deg")
        let crossSlopeValues = extractCSVValues(from: choice.value, key: "cross_slope_deg")
        
        // Check if any captures were made (array not empty)
        let hasCaptureAttempts = !widthValues.isEmpty || !slopeValues.isEmpty || !crossSlopeValues.isEmpty
        
        if hasCaptureAttempts {
            // Add AutoCapture tags (including NA values for failed captures)
            if !widthValues.isEmpty {
                submissionDict["ext:autoCapture:width"] = widthValues.joined(separator: ",")
            }
            if !slopeValues.isEmpty {
                submissionDict["ext:autoCapture:slope"] = slopeValues.joined(separator: ",")
            }
            if !crossSlopeValues.isEmpty {
                submissionDict["ext:autoCapture:cross-slope"] = crossSlopeValues.joined(separator: ",")
            }
            submissionDict["ext:autoCapture:ignored"] = "no"
        } else {
            // No capture attempts made at all
            submissionDict["ext:autoCapture:ignored"] = "yes"
        }
    }
    
    private func extractCSVValues(from csvString: String, key: String) -> [String] {
        // Extract values for a specific key from the CSV format
        // e.g., key="width_m" from "width_m:2.34,1.92|slope_deg:2.31,1.45"
        
        let parts = csvString.split(separator: "|").map(String.init)
        
        for part in parts {
            if part.hasPrefix(key + ":") {
                let valueString = String(part.dropFirst(key.count + 1))
                let values = valueString.split(separator: ",").map(String.init)
                return values
            }
        }
        
        return []
    }
}
