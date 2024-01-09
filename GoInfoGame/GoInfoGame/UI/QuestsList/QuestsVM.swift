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
            Ques(id: "AddSidewalksWidth", title: "What is the width of the most narrow usable path along this footpath? (measure with your phone please)", subtitle: "Determine sidewalk widths", answerType: AnswerType.WIDTH, answerTitle: "The roadway width from curb to curb: This includes anything on the street surface, including on-street parking or bicycle lanes but excluding anything beyond the curb like sidewalks, off-street parking or adjacent bicycle paths.", icon: "sidewalk-width-img")
        ]
    }
}
