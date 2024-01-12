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
    case IMAGEGRIDLIST
}
enum SheetSize {
    case SMALL
    case MEDIUM
    case LARGE
}
struct Ques: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var answerType: AnswerType
    var answerTitle: String?
    var icon: String
    var tag: String
    var sheetSize : SheetSize
}
class QuestsVM: ObservableObject {
    @Published var quests: [Ques] = []
    init() {
        quests = [
            Ques(id: "AddSidewalksWidth", title: LocalizedStrings.questWidthMostNarrowPath.localized, subtitle: LocalizedStrings.questDetermineSidewalkWidth.localized, answerType: AnswerType.WIDTH, answerTitle: LocalizedStrings.questRoadWithExplanation.localized, icon: "sidewalk-width-img", tag: "width", sheetSize: SheetSize.MEDIUM),
            Ques(id: "AddHandrail", title: LocalizedStrings.questHandrailTitle.localized, subtitle: LocalizedStrings.questSpecifyHandrails.localized, answerType: AnswerType.YESNO, icon: "steps_handrail", tag: "handrail", sheetSize: SheetSize.SMALL),
            Ques(id: "AddStepsRamp", title: LocalizedStrings.questHandrailTitle.localized, subtitle: LocalizedStrings.questSpecifyHandrails.localized, answerType: AnswerType.IMAGEGRIDLIST, icon: "ic_quest_steps_ramp", tag: "ramp", sheetSize: SheetSize.LARGE)
        ]
    }
}
