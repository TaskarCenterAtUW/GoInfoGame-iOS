//
//  QuestsViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/01/24.
//
import SwiftUI
import Foundation

enum AnswerType {
    case ADDSIDEWALKWIDTH
    case ADDHANDRAIL
    case ADDSTEPSRAMP
    case ADDSTEPSINCLINE
    case ADDTACTILEPAVINGSTEPS
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
            Ques(id: "AddSidewalksWidth", title: LocalizedStrings.questWidthMostNarrowPath.localized, subtitle: LocalizedStrings.questDetermineSidewalkWidth.localized, answerType: AnswerType.ADDSIDEWALKWIDTH, answerTitle: LocalizedStrings.questRoadWithExplanation.localized, icon: "sidewalk-width-img", tag: "width", sheetSize: SheetSize.MEDIUM),
            Ques(id: "AddHandrail", title: LocalizedStrings.questHandrailTitle.localized, subtitle: LocalizedStrings.questSpecifyHandrails.localized, answerType: AnswerType.ADDHANDRAIL, icon: "steps_handrail", tag: "handrail", sheetSize: SheetSize.SMALL),
            Ques(id: "AddStepsRamp", title: LocalizedStrings.questHandrailTitle.localized, subtitle: "Specify whether steps have a ramp", answerType: AnswerType.ADDSTEPSRAMP, icon: "ic_quest_steps_ramp", tag: "ramp", sheetSize: SheetSize.LARGE),
            Ques(id: "AddStepsIncline", title: LocalizedStrings.questStepsInclineTitle.localized, subtitle: "Specify which way leads up for steps", answerType: AnswerType.ADDSTEPSINCLINE, icon: "steps", tag: "incline", sheetSize: SheetSize.MEDIUM),
            Ques(id: "AddTactilePavingSteps", title: LocalizedStrings.questTactilePavingTitleSteps.localized, subtitle: "Survey tactile paving on steps", answerType: AnswerType.ADDTACTILEPAVINGSTEPS, icon: "steps_tactile_paving", tag: "tactile_paving", sheetSize: SheetSize.MEDIUM)
        ]
    }
}
//tactile_paving
