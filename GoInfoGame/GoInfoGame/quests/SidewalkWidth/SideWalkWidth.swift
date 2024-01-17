//
//  SideWalkWidth.swift
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

class SideWalkWidth : Quest {
    
    func onAnswer(answer: WidthAnswer) {
        
    }
    
    typealias AnswerClass = WidthAnswer
    
    var title: String = ""
    
    var filter: String = ""
     
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk-width-img.pdf")
    
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    var form: any View = SideWalkWidthForm()
    
    var relationData: Any? = nil
    
}

class WidthAnswer {
    let width : String
    let units: String
    let isARMeasurement : Bool
    init(width: String, units: String, isARMeasurement: Bool) {
        self.width = width
        self.units = units
        self.isARMeasurement = isARMeasurement
    }
}


