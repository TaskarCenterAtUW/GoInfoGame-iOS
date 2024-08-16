//
//  LongFormViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 02/08/24.
//

import Foundation

class LongFormViewModel: ObservableObject {
    @Published var longForm: LongFormModel?
    @Published var answers: [Int: String] = [:]
    @Published var answersToBeSubmitted: [String: String] = [:]
    @Published var selectedAnswers: [QuestAnswerChoice] = []

    init() {}
        
     func shouldShowQuest(_ quest: LongQuest) -> Bool {
        guard let dependency = quest.questAnswerDependency else {
            return true
        }
        if let answeredValue = answers[dependency.questionID] {
            return dependency.requiredValue.contains(answeredValue)
        }
        return false
    }
    
    func updateAnswers(quest: LongQuest, selectedAnswerChoice: QuestAnswerChoice) {
        selectedAnswers.append(selectedAnswerChoice)
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
