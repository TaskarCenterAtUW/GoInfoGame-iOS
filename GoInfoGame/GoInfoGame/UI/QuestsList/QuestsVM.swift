//
//  QuestsViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/01/24.
//
//import SwiftUI
import Foundation

enum AnswerType {
    case ADDSIDEWALKWIDTH
    case ADDHANDRAIL
    case ADDSTEPSRAMP
    case ADDSTEPSINCLINE
    case ADDTACTILEPAVINGSTEPS
    case ADDSTAIRNUMBER
    case ADDWAYLIT
    case ADDSTOPELIT
}
enum SheetSize {
    case SMALL
    case MEDIUM
    case LARGE
    case XLARGE
    case LONGFORM
}
//struct Ques: Identifiable, Hashable {
//    var id: String
//    var title: String
//    var subtitle: String
//    var answerType: AnswerType
//    var answerTitle: String?
//    var icon: String
//    var tag: String
//    var sheetSize : SheetSize
//}
//class QuestsVM: ObservableObject {
//     var quests: [Quest2] = []
//    init() {
//        quests = QuestsRepository.shared.applicableQuests
//    }
//}
//tactile_paving
