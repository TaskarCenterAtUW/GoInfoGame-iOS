//
//  QuestProtocols.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import UIKit
import SwiftUI
protocol Quest {
    associatedtype AnswerClass // The class that represents answer
    var title:String {get}
    var filter: String {get}
    var icon: UIImage {get}
    var wikiLink: String {get}
    var changesetComment: String {get}
    var form : any View {get set}
    var relationData : Any? {get set}
    
    func onAnswer(answer:AnswerClass)
}

protocol QuestForm {
    associatedtype AnswerClass
    
    func applyAnswer(answer:AnswerClass)
}
