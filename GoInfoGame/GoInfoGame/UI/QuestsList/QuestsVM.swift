//
//  QuestsViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/01/24.
//
import SwiftUI
import Foundation

enum AnswerType {
    case WIDTH
    case YESNO
}
struct Ques: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var answerType: AnswerType
    var answerTitle: String?
    var icon: String
}
class QuestsVM: ObservableObject {
    @Published var quests: [Ques] = []
    init() {
        quests = [
            Ques(id: "AddSidewalksWidth", title: LocalizedStrings.questWidthMostNarrowPath.localized, subtitle: LocalizedStrings.questDetermineSidewalkWidth.localized, answerType: AnswerType.WIDTH, answerTitle: LocalizedStrings.questRoadWithExplanation.localized, icon: "sidewalk-width-img"),
            Ques(id: "AddHandrail", title: LocalizedStrings.questHandrailTitle.localized, subtitle: LocalizedStrings.questSpecifyHandrails.localized, answerType: AnswerType.YESNO, icon: "steps_handrail")
        ]
    }
}
