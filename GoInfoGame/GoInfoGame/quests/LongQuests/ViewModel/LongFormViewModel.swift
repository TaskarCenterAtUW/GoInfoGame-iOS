//
//  LongFormViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 02/08/24.
//

import Foundation

class LongFormViewModel: ObservableObject {
    @Published var longForm: LongFormElement?
    @Published var answers: [Int: String] = [:]
    @Published var answersToBeSubmitted: [String: String] = [:]

    init() {}
        
     func shouldShowQuest(_ quest: LongQuest) -> Bool {
        guard let dependency = quest.questAnswerDependency else {
            return true
        }
        if let answeredValue = answers[dependency.questionID] {
            let answeredValues = answeredValue.components(separatedBy: ", ")
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
    
    func updateAnswers(quest: LongQuest, selectedAnswerChoice: QuestAnswerChoice) {
        answers[quest.questID] = selectedAnswerChoice.value
        answersToBeSubmitted[quest.questTag] = selectedAnswerChoice.value
        answersToBeRemoved()
    }
    
    func answersToBeRemoved() {
        guard let quests = longForm?.quests else { return }
        let visibleQuestTags = quests.filter { shouldShowQuest($0)}.map { $0.questTag }
        answersToBeSubmitted = answersToBeSubmitted.filter{ visibleQuestTags.contains($0.key) }
        
    }
}
