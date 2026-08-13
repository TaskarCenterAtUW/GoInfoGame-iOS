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
    
    /// Seeds `selectedChoices` from an element's existing OSM tags, so a
    /// partially-answered element opens showing what's already been answered
    /// instead of a blank form. AutoCapture is skipped — its completeness is
    /// driven entirely by the tag-based check in `LongFormElement+Completion`,
    /// independent of any in-session selection, and its capture UI always starts
    /// fresh.
    func prefillAnswers(tags: [String: String]) {
        guard let quests = longForm?.quests else { return }
        for quest in quests {
            guard quest.questType != .autoCapture,
                  let tag = quest.questTag,
                  let value = tags[tag], !value.isEmpty else { continue }
            if quest.questType == .exclusiveChoice {
                // Reuse the exact object from questAnswerChoices rather than
                // constructing a new one — QuestAnswerChoice's synthesized
                // Equatable includes its per-instance UUID, so a freshly built
                // struct would silently fail the selection-highlight `==` check
                // even with a matching value.
                if let match = quest.questAnswerChoices?.first(where: { $0.value == value }) {
                    selectedChoices[quest.questID] = match
                }
            } else {
                selectedChoices[quest.questID] = QuestAnswerChoice(value: value, choiceText: value, imageURL: nil, choiceFollowUp: nil)
            }
        }
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
    
    // Checks each answered quest's value against its quest_answer_validation, if present.
    // Returns a user-facing error message for the first violation found, or nil if all answers are valid.
    func validationErrorMessage() -> String? {
        guard let quests = longForm?.quests else { return nil }
        for quest in quests {
            guard shouldShowQuest(quest),
                  let validation = quest.questAnswerValidation,
                  let choiceOptional = selectedChoices[quest.questID],
                  let choice = choiceOptional,
                  let message = validation.errorMessage(forRawValue: choice.value) else { continue }
            return "\(quest.questTitle): \(message)"
        }
        return nil
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
                    } else if let tag = quest.questTag {
                        submissionDict[tag] = choice.value
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
        // Parse the serialized captures.
        // Format: "key=value|key=value||key=value|key=value" where "||" separates captures
        // and "|" separates OSM tags within each capture.
        let tagValuesByCaptureTag = parseAutoCaptureOSMTags(from: choice.value)

        if tagValuesByCaptureTag.isEmpty {
            submissionDict["ext:autoCapture:ignored"] = "yes"
        } else {
            // For each OSM tag, collect values across all captures as CSV and add to submission.
            for (osmTag, values) in tagValuesByCaptureTag {
                submissionDict[osmTag] = values.joined(separator: ",")
            }
            submissionDict["ext:autoCapture:ignored"] = "no"
        }
    }

    // Parses the serialized capture string and returns a dict of OSM tag → [value per capture].
    private func parseAutoCaptureOSMTags(from serialized: String) -> [String: [String]] {
        var result: [String: [String]] = [:]

        let captureBlocks = serialized.components(separatedBy: "||")
        for block in captureBlocks {
            let trimmed = block.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            for pair in trimmed.split(separator: "|") {
                let kv = String(pair).split(separator: "=", maxSplits: 1)
                guard kv.count == 2 else { continue }
                let key = String(kv[0])
                let value = String(kv[1])
                result[key, default: []].append(value)
            }
        }

        return result
    }
}
