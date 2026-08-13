//
//  LongFormElement+Completion.swift
//  GoInfoGame
//

import Foundation

extension LongFormElement {
    /// True when every currently-applicable question in this quest set has an
    /// answer reflected in `tags`. Dependency-hidden follow-up questions don't
    /// count toward completion. An AutoCapture question is trivially considered
    /// answered on a device that can't run it at all.
    func isFullyAnswered(tags: [String: String],
                          isAutoCaptureCapable: Bool = LiDARDetection.shared.isLiDARSupported()) -> Bool {
        for quest in quests {
            guard isQuestApplicable(quest, tags: tags) else { continue }
            if !isQuestAnswered(quest, tags: tags, isAutoCaptureCapable: isAutoCaptureCapable) { return false }
        }
        return true
    }

    /// Tag-based counterpart to `LongFormViewModel.checkDependency`, which reads
    /// from in-session `selectedChoices` — this reads from an element's actual
    /// OSM tags instead, since completeness is evaluated outside any form session.
    /// Splits on ";" to match the separator `MultipleChoiceView` actually writes
    /// (`QuestOptions.swift`), not the ", " the session-based check uses.
    private func isQuestApplicable(_ quest: LongQuest, tags: [String: String]) -> Bool {
        guard let dependencies = quest.questAnswerDependency else { return true }
        for dependency in dependencies {
            guard let depQuest = quests.first(where: { $0.questID == dependency.questionID }),
                  let depTag = depQuest.questTag,
                  let depValue = tags[depTag], !depValue.isEmpty else { return false }
            let answeredValues = depValue.components(separatedBy: ";")
            switch dependency.requiredValue {
            case .string(let required):
                if !answeredValues.contains(required) { return false }
            case .array(let required):
                if Set(answeredValues).isDisjoint(with: Set(required)) { return false }
            }
        }
        return true
    }

    private func isQuestAnswered(_ quest: LongQuest, tags: [String: String], isAutoCaptureCapable: Bool) -> Bool {
        if quest.questType == .autoCapture {
            guard isAutoCaptureCapable else { return true } // incapable device: not a blocking question
            guard let attributes = quest.autoCaptureAttributes else { return true }
            return attributes.values.contains { tags[$0]?.isEmpty == false }
        }
        guard let tag = quest.questTag else { return true }
        return tags[tag]?.isEmpty == false
    }
}
