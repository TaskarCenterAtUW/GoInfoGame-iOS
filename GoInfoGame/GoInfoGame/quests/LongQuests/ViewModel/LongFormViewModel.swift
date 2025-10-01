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
        
        for quest in quests {
            if let choiceOptional = selectedChoices[quest.questID], let choice = choiceOptional {
                if shouldShowQuest(quest) {
                    submissionDict[quest.questTag] = choice.value
                }
            }
        }
        return submissionDict
    }
}
